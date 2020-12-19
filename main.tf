
##VPC

module "vpc" {
  source     = "./TF-VPC"
  namespace  = var.namespace
  stage      = var.environment
  name       = var.project
  attributes = ["test"]
  cidr_block = "172.16.0.0/16"
  tags       = local.tags
}

module "subnets" {
  source               = "./TF-SUBNET"
  availability_zones   = var.availability_zones
  namespace            = var.namespace
  stage                = var.environment
  name                 = var.project
  attributes           = ["test"]
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false
  tags                 = local.tags
}

##KMS

module "kms_key" {
  source                  = "./TF-KMS" //ruta local
  region                  = var.region
  namespace               = var.namespace
  environment             = var.environment
  project                 = var.project
  description             = format("KMS key cuenta: %s Proyecto: %s Environment: %s", var.aws_account_id_project, var.project, var.environment )
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  tags                    = var.tags
  aws_account_id          = var.aws_account_id_glyc
  aws_account_id_key_project      = var.aws_account_id_project
  policy                  = local.policy
  #alias_account_project   = var.alias_account_project
  }


module "eks_cluster" {
  source                       = "./TF-EKS-CLUSTER/"
  namespace                    = var.namespace
  environment                  = var.environment
  project                      = var.project
  tags                         = var.tags
  region                       = var.region
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.subnets.public_subnet_ids
  kubernetes_version           = var.kubernetes_version
  local_exec_interpreter       = var.local_exec_interpreter
  oidc_provider_enabled        = var.oidc_provider_enabled
  enabled_cluster_log_types    = var.enabled_cluster_log_types
  cluster_log_retention_period = var.cluster_log_retention_period
  map_additional_iam_roles     = local.build_role_arn
  cluster_encryption_config_kms_key_id   = module.kms_key.key_arn
  aws_account_id               = var.aws_account_id_project
}

# Ensure ordering of resource creation to eliminate the race conditions when applying the Kubernetes Auth ConfigMap.
# Do not create Node Group before the EKS cluster is created and the `aws-auth` Kubernetes ConfigMap is applied.
# Otherwise, EKS will create the ConfigMap first and add the managed node role ARNs to it,
# and the kubernetes provider will throw an error that the ConfigMap already exists (because it can't update the map, only create it).
# If we create the ConfigMap first (to add additional roles/users/accounts), EKS will just update it by adding the managed node role ARNs.
data "null_data_source" "wait_for_cluster_and_kubernetes_configmap" {
  inputs = {
    cluster_name             = module.eks_cluster.eks_cluster_id
    kubernetes_config_map_id = module.eks_cluster.kubernetes_config_map_id
  }
}

module "eks_node_group" {
  source            = "./TF-EKS-NODE-GROUP/"
  region            = var.region
  namespace         = var.namespace
  environment       = var.environment
  project           = var.project
  tags              = var.tags
  subnet_ids        = module.subnets.public_subnet_ids
  cluster_name      = data.null_data_source.wait_for_cluster_and_kubernetes_configmap.outputs["cluster_name"]
  instance_types    = var.instance_types
  desired_size      = var.desired_size
  min_size          = var.min_size
  max_size          = var.max_size
  kubernetes_labels = var.kubernetes_labels
  disk_size         = var.disk_size
  enable_cluster_autoscaler = var.enable_cluster_autoscaler
  enable_cluster_cloudwatchlogs = var.enable_cluster_cloudwatchlogs
  aws_account_id    = var.aws_account_id_project
}

# Elastic Container Registry Docker Repository
module "ecr" {
  #count      = lenght(var.images)
  source     = "./TF-ECR/"
  region     = var.region
  project    = var.project
  subproject = var.subproject
  image_names = var.image_names
  tags       = var.tags
  aws_account_id    = var.aws_account_id_project
}