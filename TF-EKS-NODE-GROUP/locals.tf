locals {
  tags = merge(
    var.tags,
    { "Name" = format("%s-%s-eks-%s-cluster", var.namespace, var.environment, var.project) }, {"Project" = var.project},
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
    },
    {
      "k8s.io/cluster-autoscaler/enabled" = "${var.enable_cluster_autoscaler}"
    }
  )
  aws_policy_prefix = format("arn:%s:iam::aws:policy", join("", data.aws_partition.current.*.partition))
}


data "aws_partition" "current" {
  count = var.enabled ? 1 : 0
}



data "aws_subnet" "selected" {
  count = length(var.subnet_ids)  
  id = element(var.subnet_ids, count.index)
}