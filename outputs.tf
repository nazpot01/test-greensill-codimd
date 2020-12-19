output "region" {
  value = "${var.region}"
}

#EKS

output "eks_cluster_security_group_id" {
  description = "ID of the EKS cluster Security Group"
  value       = join("", module.eks_cluster.cluster_security_group_id)
}

output "eks_security_group_arn" {
  description = "ARN of the EKS cluster Security Group"
  value       =  module.eks_cluster.security_group_arn
}

output "eks_cluster_id" {
  description = "The name of the cluster"
  value       = module.eks_cluster.eks_cluster_id
}

output "eks_cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks_cluster.eks_cluster_arn
}

output "eks_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.eks_cluster.eks_cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes server version of the cluster"
  value       = module.eks_cluster.eks_cluster_version
}

output "eks_cluster_identity_oidc_issuer" {
  description = "The OIDC Identity issuer for the cluster"
  value       = module.eks_cluster.eks_cluster_identity_oidc_issuer
}

output "eks_cluster_identity_oidc_issuer_arn" {
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
  value       = module.eks_cluster.eks_cluster_identity_oidc_issuer_arn
}

# output "eks_cluster_certificate_authority_data" {
#   description = "The Kubernetes cluster certificate authority data"
#   value       = module.eks_cluster.eks_cluster_certificate_authority_data
# }

output "eks_cluster_managed_security_group_id" {
  description = "Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads"
  value       = module.eks_cluster.eks_cluster_managed_security_group_id
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.eks_cluster.eks_cluster_role_arn
}

output "eks_kubernetes_config_map_id" {
  description = "ID of `aws-auth` Kubernetes ConfigMap"
  value       = module.eks_cluster.kubernetes_config_map_id
}

output "eks_cluster_name" {
  description = "Name cluster EKS"
  value       = module.eks_cluster.eks_cluster_name
}

#NODE GROUP

output "eks_node_group_role_arn" {
  description = "ARN of the worker nodes IAM role"
  value       = module.eks_node_group.eks_node_group_role_arn
}

output "eks_node_group_role_name" {
  description = "Name of the worker nodes IAM role"
  value       = module.eks_node_group.eks_node_group_role_name
}

output "eks_node_group_id" {
  description = "EKS Cluster name and EKS Node Group name separated by a colon"
  value       = module.eks_node_group.eks_node_group_id
}

output "eks_node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = module.eks_node_group.eks_node_group_arn
}

output "eks_node_group_resources" {
  description = "List of objects containing information about underlying resources of the EKS Node Group"
  value       = module.eks_node_group.eks_node_group_resources
}

output "eks_node_group_status" {
  description = "Status of the EKS Node Group"
  value       = module.eks_node_group.eks_node_group_status
}



#ECR

output "ecr_registry_id" {
  value       = module.ecr.registry_id
  description = "Registry ID"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "Registry URL"
}

output "ecr_repository_name" {
  value       = module.ecr.repository_name
  description = "Registry name"
}

#KMS
output "key_arn" {
  value       = module.kms_key.key_arn
  description = "Key ARN"
}

output "key_id" {
  value       = module.kms_key.key_id
  description = "Key ID"
}

output "alias_arn" {
  value       = module.kms_key.alias_arn
  description = "Alias ARN"
}

output "alias_name" {
  value       = module.kms_key.alias_name
  description = "Alias name"
}

