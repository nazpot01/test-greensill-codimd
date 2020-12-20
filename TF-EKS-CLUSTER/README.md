## Introduction

The module provisions the following resources:

- EKS cluster of master nodes that can be used together with the [terraform-aws-eks-workers](https://github.com/cloudposse/terraform-aws-eks-workers),
  [terraform-aws-eks-node-group](https://github.com/cloudposse/terraform-aws-eks-node-group) and
  [terraform-aws-eks-fargate-profile](https://github.com/cloudposse/terraform-aws-eks-fargate-profile)
  modules to create a full-blown cluster
- IAM Role to allow the cluster to access other AWS services
- Security Group which is used by EKS workers to connect to the cluster and kubelets and pods to receive communication from the cluster control plane
- The module creates and automatically applies an authentication ConfigMap to allow the wrokers nodes to join the cluster and to add additional users/roles/accounts

__NOTE:__ The module works with [Terraform Cloud](https://www.terraform.io/docs/cloud/index.html).

__NOTE:__ In `auth.tf`, we added `ignore_changes = [data["mapRoles"]]` to the `kubernetes_config_map` for the following reason:
- We provision the EKS cluster and then the Kubernetes Auth ConfigMap to map additional roles/users/accounts to Kubernetes groups
- Then we wait for the cluster to become available and for the ConfigMap to get provisioned (see `data "null_data_source" "wait_for_cluster_and_kubernetes_configmap"` in `examples/complete/main.tf`)
- Then we provision a managed Node Group
- Then EKS updates the Auth ConfigMap and adds worker roles to it (for the worker nodes to join the cluster)
- Since the ConfigMap is modified outside of Terraform state, Terraform wants to update it (remove the roles that EKS added) on each `plan/apply`

If you want to modify the Node Group (e.g. add more Node Groups to the cluster) or need to map other IAM roles to Kubernetes groups,
set the variable `kubernetes_config_map_ignore_role_changes` to `false` and re-provision the module. Then set `kubernetes_config_map_ignore_role_changes` back to `true`.

## Usage


**IMPORTANT:** The `master` branch is used in `source` just as an example. In your code, do not pin to `master` because there may be breaking changes between releases.
Instead pin to the release tag (e.g. `?ref=tags/x.y.z`) of one of our [latest releases](https://github.com/cloudposse/terraform-aws-eks-cluster/releases).



For a complete example, see [examples/complete](examples/complete).

For automated tests of the complete example using [bats](https://github.com/bats-core/bats-core) and [Terratest](https://github.com/gruntwork-io/terratest) (which tests and deploys the example on AWS), see [test](test).

Other examples:

- [terraform-root-modules/eks](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/eks) - Cloud Posse's service catalog of "root module" invocations for provisioning reference architectures
- [terraform-root-modules/eks-backing-services-peering](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/eks-backing-services-peering) - example of VPC peering between the EKS VPC and backing services VPC

```hcl
  provider "aws" {
    region = var.region
  }

  module "label" {
    source     = "git::https://github.com/cloudposse/terraform-null-label.git?ref=master"
    namespace  = var.namespace
    name       = var.name
    stage      = var.stage
    delimiter  = var.delimiter
    attributes = compact(concat(var.attributes, list("cluster")))
    tags       = var.tags
  }

  locals {
    # The usage of the specific kubernetes.io/cluster/* resource tags below are required
    # for EKS and Kubernetes to discover and manage networking resources
    # https://www.terraform.io/docs/providers/aws/guides/eks-getting-started.html#base-vpc-networking
    tags = merge(var.tags, map("kubernetes.io/cluster/${module.label.id}", "shared"))

    # Unfortunately, most_recent (https://github.com/cloudposse/terraform-aws-eks-workers/blob/34a43c25624a6efb3ba5d2770a601d7cb3c0d391/main.tf#L141)
    # variable does not work as expected, if you are not going to use custom AMI you should
    # enforce usage of eks_worker_ami_name_filter variable to set the right kubernetes version for EKS workers,
    # otherwise the first version of Kubernetes supported by AWS (v1.11) for EKS workers will be used, but
    # EKS control plane will use the version specified by kubernetes_version variable.
    eks_worker_ami_name_filter = "amazon-eks-node-${var.kubernetes_version}*"
  }

  module "vpc" {
    source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=master"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    cidr_block = "172.16.0.0/16"
    tags       = local.tags
  }

  module "subnets" {
    source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
    availability_zones   = var.availability_zones
    namespace            = var.namespace
    stage                = var.stage
    name                 = var.name
    attributes           = var.attributes
    vpc_id               = module.vpc.vpc_id
    igw_id               = module.vpc.igw_id
    cidr_block           = module.vpc.vpc_cidr_block
    nat_gateway_enabled  = false
    nat_instance_enabled = false
    tags                 = local.tags
  }

  module "eks_workers" {
    source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=master"
    namespace                          = var.namespace
    stage                              = var.stage
    name                               = var.name
    attributes                         = var.attributes
    tags                               = var.tags
    instance_type                      = var.instance_type
    eks_worker_ami_name_filter          = local.eks_worker_ami_name_filter
    vpc_id                             = module.vpc.vpc_id
    subnet_ids                         = module.subnets.public_subnet_ids
    health_check_type                  = var.health_check_type
    min_size                           = var.min_size
    max_size                           = var.max_size
    wait_for_capacity_timeout          = var.wait_for_capacity_timeout
    cluster_name                       = module.label.id
    cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
    cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
    cluster_security_group_id          = module.eks_cluster.security_group_id

    # Auto-scaling policies and CloudWatch metric alarms
    autoscaling_policies_enabled           = var.autoscaling_policies_enabled
    cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
    cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent
  }

  module "eks_cluster" {
    source     = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=master"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    tags       = var.tags
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.subnets.public_subnet_ids

    kubernetes_version    = var.kubernetes_version
    oidc_provider_enabled = false

    workers_security_group_ids   = [module.eks_workers.security_group_id]
    workers_role_arns            = [module.eks_workers.workers_role_arn]
  }
```

Module usage with two worker groups:

```hcl
  module "eks_workers" {
    source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=master"
    namespace                          = var.namespace
    stage                              = var.stage
    name                               = "small"
    attributes                         = var.attributes
    tags                               = var.tags
    instance_type                      = "t3.small"
    vpc_id                             = module.vpc.vpc_id
    subnet_ids                         = module.subnets.public_subnet_ids
    health_check_type                  = var.health_check_type
    min_size                           = var.min_size
    max_size                           = var.max_size
    wait_for_capacity_timeout          = var.wait_for_capacity_timeout
    cluster_name                       = module.label.id
    cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
    cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
    cluster_security_group_id          = module.eks_cluster.security_group_id

    # Auto-scaling policies and CloudWatch metric alarms
    autoscaling_policies_enabled           = var.autoscaling_policies_enabled
    cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
    cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent
  }

  module "eks_workers_2" {
    source                             = "git::https://github.com/cloudposse/terraform-aws-eks-workers.git?ref=master"
    namespace                          = var.namespace
    stage                              = var.stage
    name                               = "medium"
    attributes                         = var.attributes
    tags                               = var.tags
    instance_type                      = "t3.medium"
    vpc_id                             = module.vpc.vpc_id
    subnet_ids                         = module.subnets.public_subnet_ids
    health_check_type                  = var.health_check_type
    min_size                           = var.min_size
    max_size                           = var.max_size
    wait_for_capacity_timeout          = var.wait_for_capacity_timeout
    cluster_name                       = module.label.id
    cluster_endpoint                   = module.eks_cluster.eks_cluster_endpoint
    cluster_certificate_authority_data = module.eks_cluster.eks_cluster_certificate_authority_data
    cluster_security_group_id          = module.eks_cluster.security_group_id

    # Auto-scaling policies and CloudWatch metric alarms
    autoscaling_policies_enabled           = var.autoscaling_policies_enabled
    cpu_utilization_high_threshold_percent = var.cpu_utilization_high_threshold_percent
    cpu_utilization_low_threshold_percent  = var.cpu_utilization_low_threshold_percent
  }

  module "eks_cluster" {
    source     = "git::https://github.com/cloudposse/terraform-aws-eks-cluster.git?ref=master"
    namespace  = var.namespace
    stage      = var.stage
    name       = var.name
    attributes = var.attributes
    tags       = var.tags
    vpc_id     = module.vpc.vpc_id
    subnet_ids = module.subnets.public_subnet_ids

    kubernetes_version    = var.kubernetes_version
    oidc_provider_enabled = false

    workers_role_arns          = [module.eks_workers.workers_role_arn, module.eks_workers_2.workers_role_arn]
    workers_security_group_ids = [module.eks_workers.security_group_id, module.eks_workers_2.security_group_id]
  }
```






## Makefile Targets
```
Available targets:

  help                                Help screen
  help/all                            Display help for all targets
  help/short                          This help short screen
  lint                                Lint terraform code

```
## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |
| aws | ~> 2.0 |
| kubernetes | ~> 1.11 |
| local | ~> 1.3 |
| null | ~> 2.0 |
| template | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 2.0 |
| kubernetes | ~> 1.11 |
| null | ~> 2.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_cidr\_blocks | List of CIDR blocks to be allowed to connect to the EKS cluster | `list(string)` | `[]` | no |
| allowed\_security\_groups | List of Security Group IDs to be allowed to connect to the EKS cluster | `list(string)` | `[]` | no |
| apply\_config\_map\_aws\_auth | Whether to apply the ConfigMap to allow worker nodes to join the EKS cluster and allow additional users, accounts and roles to acces the cluster | `bool` | `true` | no |
| attributes | Additional attributes (e.g. `1`) | `list(string)` | `[]` | no |
| cluster\_log\_retention\_period | Number of days to retain cluster logs. Requires `enabled_cluster_log_types` to be set. See https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. | `number` | `0` | no |
| delimiter | Delimiter to be used between `namespace`, `environment`, `stage`, `name` and `attributes` | `string` | `"-"` | no |
| enabled | Set to false to prevent the module from creating any resources | `bool` | `true` | no |
| enabled\_cluster\_log\_types | A list of the desired control plane logging to enable. For more information, see https://docs.aws.amazon.com/en_us/eks/latest/userguide/control-plane-logs.html. Possible values [`api`, `audit`, `authenticator`, `controllerManager`, `scheduler`] | `list(string)` | `[]` | no |
| endpoint\_private\_access | Indicates whether or not the Amazon EKS private API server endpoint is enabled. Default to AWS EKS resource and it is false | `bool` | `false` | no |
| endpoint\_public\_access | Indicates whether or not the Amazon EKS public API server endpoint is enabled. Default to AWS EKS resource and it is true | `bool` | `true` | no |
| environment | Environment, e.g. 'prod', 'staging', 'dev', 'pre-prod', 'UAT' | `string` | `""` | no |
| kubernetes\_config\_map\_ignore\_role\_changes | Set to `true` to ignore IAM role changes in the Kubernetes Auth ConfigMap | `bool` | `true` | no |
| kubernetes\_version | Desired Kubernetes master version. If you do not specify a value, the latest available version is used | `string` | `"1.15"` | no |
| local\_exec\_interpreter | shell to use for local\_exec | `list(string)` | <pre>[<br>  "/bin/sh",<br>  "-c"<br>]</pre> | no |
| map\_additional\_aws\_accounts | Additional AWS account numbers to add to `config-map-aws-auth` ConfigMap | `list(string)` | `[]` | no |
| map\_additional\_iam\_roles | Additional IAM roles to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| map\_additional\_iam\_users | Additional IAM users to add to `config-map-aws-auth` ConfigMap | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `""` | no |
| namespace | Namespace, which could be your organization name or abbreviation, e.g. 'eg' or 'cp' | `string` | `""` | no |
| oidc\_provider\_enabled | Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html | `bool` | `false` | no |
| public\_access\_cidrs | Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled. EKS defaults this to a list with 0.0.0.0/0. | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| region | AWS Region | `string` | n/a | yes |
| stage | Stage, e.g. 'prod', 'staging', 'dev', OR 'source', 'build', 'test', 'deploy', 'release' | `string` | `""` | no |
| subnet\_ids | A list of subnet IDs to launch the cluster in | `list(string)` | n/a | yes |
| tags | Additional tags (e.g. `map('BusinessUnit','XYZ')` | `map(string)` | `{}` | no |
| vpc\_id | VPC ID for the EKS cluster | `string` | n/a | yes |
| wait\_for\_cluster\_command | `local-exec` command to execute to determine if the EKS cluster is healthy. Cluster endpoint are available as environment variable `ENDPOINT` | `string` | `"curl --silent --fail --retry 60 --retry-delay 5 --retry-connrefused --insecure --output /dev/null $ENDPOINT/healthz"` | no |
| workers\_role\_arns | List of Role ARNs of the worker nodes | `list(string)` | `[]` | no |
| workers\_security\_group\_ids | Security Group IDs of the worker nodes | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| eks\_cluster\_arn | The Amazon Resource Name (ARN) of the cluster |
| eks\_cluster\_certificate\_authority\_data | The Kubernetes cluster certificate authority data |
| eks\_cluster\_endpoint | The endpoint for the Kubernetes API server |
| eks\_cluster\_id | The name of the cluster |
| eks\_cluster\_identity\_oidc\_issuer | The OIDC Identity issuer for the cluster |
| eks\_cluster\_identity\_oidc\_issuer\_arn | The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account |
| eks\_cluster\_managed\_security\_group\_id | Security Group ID that was created by EKS for the cluster. EKS creates a Security Group and applies it to ENI that is attached to EKS Control Plane master nodes and to any managed workloads |
| eks\_cluster\_role\_arn | ARN of the EKS cluster IAM role |
| eks\_cluster\_version | The Kubernetes server version of the cluster |
| kubernetes\_config\_map\_id | ID of `aws-auth` Kubernetes ConfigMap |
| security\_group\_arn | ARN of the EKS cluster Security Group |
| security\_group\_id | ID of the EKS cluster Security Group |
| security\_group\_name | Name of the EKS cluster Security Group |
