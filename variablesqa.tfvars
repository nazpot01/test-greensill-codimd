
#VPC

region = "us-west-2"
availability_zones = ["us-west-2a", "us-west-2b"]
cidr = "172.16.0.0/16"
cidr_block = "172.16.0.0/16"


#SUBRED

stage = "test"
name = "subnets-vpc-test"


#VARIABLES GENERALES

aws_account_id_project = 123456789987
aws_account_id_glyc = 123456789987
subproject = "codimd"
project = "codimd"
image_names = ["node"]

#EKS

namespace = "test"
environment = "qa"
kubernetes_version = "1.17"
oidc_provider_enabled = true
enabled_cluster_log_types = ["audit"]
enable_cluster_autoscaler = true
enable_cluster_cloudwatchlogs = true
cluster_log_retention_period = 7
instance_types = ["t3.medium"]
desired_size = 2
max_size = 3
min_size = 2
disk_size = 20
kubernetes_labels = {}


tags = {
        "Team"        =  "DevOps"
        "Environment" =  "qa"
        "Deploy"      =  "Terraform"
    }


##KMS

deletion_window_in_days = 7
enable_key_rotation     = false





