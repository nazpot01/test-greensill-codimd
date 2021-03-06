locals {
  cluster_encryption_config = {
    resources        = var.cluster_encryption_config_resources
    provider_key_arn = var.cluster_encryption_config_enabled ? var.cluster_encryption_config_kms_key_id : ""
  }
}

data "aws_partition" "current" {
  count = var.enabled ? 1 : 0
}

data "aws_iam_policy_document" "assume_role" {
  count = var.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "default" {
  count              = var.enabled ? 1 : 0
  name               = format("%s-%s-role-%s-ekscluster", var.namespace, var.environment, var.project)
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags               =  merge({ "Name" = format("%s-%s-role-%s-ekscluster", var.namespace, var.environment, var.project) }, {"Project" = var.project}, var.tags)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cluster_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSClusterPolicy", join("", data.aws_partition.current.*.partition))
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_service_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = format("arn:%s:iam::aws:policy/AmazonEKSServicePolicy", join("", data.aws_partition.current.*.partition))
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_security_group" "default" {
  count       = var.enabled ? 1 : 0
  name        = format("%s-%s-sg-%s-ekscluster", var.namespace, var.environment, var.project)
  description = "Security Group for EKS cluster"
  vpc_id      = var.vpc_id
  tags        = merge({ "Name" = format("%s-%s-sg-%s-ekscluster", var.namespace, var.environment, var.project) }, {"Project" = var.project}, var.tags)
}

resource "aws_security_group_rule" "egress" {
  count             = var.enabled ? 1 : 0
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.default.*.id)
  type              = "egress"
}

resource "aws_security_group_rule" "ingress_workers" {
  count                    = var.enabled ? length(var.workers_security_group_ids) : 0
  description              = "Allow the cluster to receive communication from the worker nodes"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = var.workers_security_group_ids[count.index]
  security_group_id        = join("", aws_security_group.default.*.id)
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_security_groups" {
  count                    = var.enabled ? length(var.allowed_security_groups) : 0
  description              = "Allow inbound traffic from existing Security Groups"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = var.allowed_security_groups[count.index]
  security_group_id        = join("", aws_security_group.default.*.id)
  type                     = "ingress"
}

resource "aws_security_group_rule" "ingress_cidr_blocks" {
  count             = var.enabled && length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  description       = "Allow inbound traffic from CIDR blocks"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = join("", aws_security_group.default.*.id)
  type              = "ingress"
}

resource "aws_cloudwatch_log_group" "default" {
  count             = var.enabled && length(var.enabled_cluster_log_types) > 0 ? 1 : 0
  name              = "/aws/eks/${format("%s-%s-%s-cluster", var.namespace, var.environment, var.project)}/cluster"
  retention_in_days = var.cluster_log_retention_period
  tags              = merge({ "Name" = format("%s-%s-cw-%s-cluster", var.namespace, var.environment, var.project) }, {"Project" = var.project}, var.tags)
}

resource "aws_eks_cluster" "default" {
  count                     = var.enabled ? 1 : 0
  name                      = format("%s-%s-eks-%s-cluster", var.namespace, var.environment, var.project)
  tags                      = merge({ "Name" = format("%s-%s-eks-%s-cluster", var.namespace, var.environment, var.project) }, {"Project" = var.project}, var.tags)
  role_arn                  = join("", aws_iam_role.default.*.arn)
  version                   = var.kubernetes_version
  enabled_cluster_log_types = var.enabled_cluster_log_types


  dynamic "encryption_config" {
    for_each = var.cluster_encryption_config_enabled ? [local.cluster_encryption_config] : []
    content {
      resources = lookup(encryption_config.value, "resources")
      provider {
        key_arn = lookup(encryption_config.value, "provider_key_arn")
      }
    }
  }

  vpc_config {
    security_group_ids      = [join("", aws_security_group.default.*.id)]
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.amazon_eks_service_policy,
    aws_cloudwatch_log_group.default
  ]
}

# Enabling IAM Roles for Service Accounts in Kubernetes cluster

resource "aws_iam_openid_connect_provider" "default" {
  count = (var.enabled && var.oidc_provider_enabled) ? 1 : 0
  url   = join("", aws_eks_cluster.default.*.identity.0.oidc.0.issuer)

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}
