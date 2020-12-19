
resource "aws_iam_policy" "amazon_eks_worker_node_autoscaler_policy" {
  count  = (var.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  name   = format("%s-%s-poli-%s-autoscaler", var.namespace, var.environment, var.project)
  path   = "/"
  policy = join("", data.aws_iam_policy_document.amazon_eks_worker_node_autoscaler_policy.*.json)
}

resource "aws_iam_policy" "amazon_eks_worker_node_cloudwatchlogs_policy" {
  count  = (var.enabled && var.enable_cluster_cloudwatchlogs) ? 1 : 0
  name   = format("%s-%s-poli-%s-cloudwatchlogs", var.namespace, var.environment, var.project)
  path   = "/"
  policy = join("", data.aws_iam_policy_document.amazon_eks_worker_node_cloudwatchlogs_policy.*.json)
}

# resource "aws_iam_policy" "albingresscontroller" {
#   name   = format("%s-%s-poli-%s-ALBIngressControllerIAMPolicy", var.namespace, var.environment, var.project)
#   path   = "/"
#   policy = data.aws_iam_policy_document.albingresscontroller.json
#  # policy = concat(data.aws_iam_policy_document.albingresscontroller.json, data.aws_iam_policy_document.albingresscontroller2.json, data.aws_iam_policy_document.albingresscontroller3.json, data.aws_iam_policy_document.albingresscontroller4.json, data.aws_iam_policy_document.albingresscontroller5.json)
# }

resource "aws_iam_role" "default" {
  count              = var.enabled ? 1 : 0
  name               = format("%s-%s-role-%s-workers", var.namespace, var.environment, var.project)
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags               = local.tags
}

# resource "aws_iam_role_policy_attachment" "albingresscontroller" {
#   count      = var.enabled ? 1 : 0
#   policy_arn = aws_iam_policy.albingresscontroller.arn
#   role       = join("", aws_iam_role.default.*.name)
# }

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKSWorkerNodePolicy")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_autoscaler_policy" {
  count      = (var.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  policy_arn = join("", aws_iam_policy.amazon_eks_worker_node_autoscaler_policy.*.arn)
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_cloudwatchlogs_policy" {
  count      = (var.enabled && var.enable_cluster_cloudwatchlogs) ? 1 : 0
  policy_arn = join("", aws_iam_policy.amazon_eks_worker_node_cloudwatchlogs_policy.*.arn)
  role       = join("", aws_iam_role.default.*.name)
}



resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  count      = var.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEKS_CNI_Policy")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  count      = var.enabled ? 1 : 0
  policy_arn = format("%s/%s", local.aws_policy_prefix, "AmazonEC2ContainerRegistryReadOnly")
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_iam_role_policy_attachment" "existing_policies_for_eks_workers_role" {
  count      = var.enabled ? var.existing_workers_role_policy_arns_count : 0
  policy_arn = var.existing_workers_role_policy_arns[count.index]
  role       = join("", aws_iam_role.default.*.name)
}

resource "aws_eks_node_group" "default" {
  count           = var.enabled ? 1 : 0
  cluster_name    = var.cluster_name
  node_group_name = format("%s-%s-ng-%s", var.namespace, var.environment, var.project)
  node_role_arn   = join("", aws_iam_role.default.*.arn)
  subnet_ids      = var.subnet_ids
  ami_type        = var.ami_type
  disk_size       = var.disk_size
  instance_types  = var.instance_types
  labels          = var.kubernetes_labels
  release_version = var.ami_release_version
  version         = var.kubernetes_version

  tags = local.tags

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  dynamic "remote_access" {
    for_each = var.ec2_ssh_key != null && var.ec2_ssh_key != "" ? ["true"] : []
    content {
      ec2_ssh_key               = var.ec2_ssh_key
      source_security_group_ids = var.source_security_group_ids
    }
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_worker_node_autoscaler_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
    # Also allow calling module to create an explicit dependency
    # This is useful in conjunction with terraform-aws-eks-cluster to ensure
    # the cluster is fully created and configured before creating any node groups
    var.module_depends_on
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}
