
data "aws_iam_policy_document" "assume_role" {
  count = var.enabled ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "amazon_eks_worker_node_autoscaler_policy" {
  count = (var.enabled && var.enable_cluster_autoscaler) ? 1 : 0
  statement {
    sid = "AllowToScaleEKSNodeGroupAutoScalingGroup"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "amazon_eks_worker_node_cloudwatchlogs_policy" {
  count = (var.enabled && var.enable_cluster_cloudwatchlogs) ? 1 : 0
  statement {
    
    effect = "Allow"

    actions = [
        "logs:ListTagsLogGroup",
        "logs:CreateLogStream",
        "logs:CreateLogGroup",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:DescribeSubscriptionFilters",
        "logs:StartQuery",
        "logs:GetLogEvents",
        "logs:DescribeMetricFilters",
        "logs:FilterLogEvents",
        "logs:GetLogGroupFields"
    ]

    resources = [
      "*"
    ]

  }
}

# data "aws_iam_policy_document" "albingresscontroller" {
#   statement {
    
#     effect = "Allow"

#     actions = [
#         "ec2:AuthorizeSecurityGroupIngress",
#         "ec2:CreateSecurityGroup",
#         "ec2:CreateTags",
#         "ec2:DeleteTags",
#         "ec2:DeleteSecurityGroup",
#         "ec2:DescribeAccountAttributes",
#         "ec2:DescribeAddresses",
#         "ec2:DescribeInstances",
#         "ec2:DescribeInstanceStatus",
#         "ec2:DescribeInternetGateways",
#         "ec2:DescribeNetworkInterfaces",
#         "ec2:DescribeSecurityGroups",
#         "ec2:DescribeSubnets",
#         "ec2:DescribeTags",
#         "ec2:DescribeVpcs",
#         "ec2:ModifyInstanceAttribute",
#         "ec2:ModifyNetworkInterfaceAttribute",
#         "ec2:RevokeSecurityGroupIngress"
#     ]

#     resources = [
#       "*"
#     ]

#   }
# }

# data "aws_iam_policy_document" "albingresscontroller2" {
#   statement {
    
#     effect = "Allow"

#     actions = [
#         "elasticloadbalancing:DescribeRules",
#         "elasticloadbalancing:DescribeSSLPolicies",
#         "elasticloadbalancing:DescribeTags",
#         "elasticloadbalancing:DescribeTargetGroups",
#         "elasticloadbalancing:DescribeTargetGroupAttributes",
#         "elasticloadbalancing:DescribeTargetHealth",
#         "elasticloadbalancing:ModifyListener",
#         "elasticloadbalancing:ModifyLoadBalancerAttributes",
#         "elasticloadbalancing:ModifyRule",
#         "elasticloadbalancing:ModifyTargetGroup",
#         "elasticloadbalancing:ModifyTargetGroupAttributes",
#         "elasticloadbalancing:RegisterTargets",
#         "elasticloadbalancing:RemoveListenerCertificates",
#         "elasticloadbalancing:RemoveTags",
#         "elasticloadbalancing:SetIpAddressType",
#         "elasticloadbalancing:SetSecurityGroups",
#         "elasticloadbalancing:SetSubnets",
#         "elasticloadbalancing:SetWebAcl"
#      ]

#     resources = [
#       "*"
#     ]

#   }
# }

# data "aws_iam_policy_document" "albingresscontroller3" {
#   statement {
    
#     effect = "Allow"

#     actions = [
#         "elasticloadbalancing:AddListenerCertificates",
#         "elasticloadbalancing:AddTags",
#         "elasticloadbalancing:CreateListener",
#         "elasticloadbalancing:CreateLoadBalancer",
#         "elasticloadbalancing:CreateRule",
#         "elasticloadbalancing:CreateTargetGroup",
#         "elasticloadbalancing:DeleteListener",
#         "elasticloadbalancing:DeleteLoadBalancer",
#         "elasticloadbalancing:DeleteRule",
#         "elasticloadbalancing:DeleteTargetGroup",
#         "elasticloadbalancing:DeregisterTargets",
#         "elasticloadbalancing:DescribeListenerCertificates",
#         "elasticloadbalancing:DescribeListeners",
#         "elasticloadbalancing:DescribeLoadBalancers",
#         "elasticloadbalancing:DescribeLoadBalancerAttributes",
#     ]

#     resources = [
#       "*"
#     ]

#   }
# }

# data "aws_iam_policy_document" "albingresscontroller4" {
#   statement {
    
#     effect = "Allow"

#     actions = [
#         "acm:DescribeCertificate",
#         "acm:ListCertificates",
#         "acm:GetCertificate",
#         "iam:CreateServiceLinkedRole",
#         "iam:GetServerCertificate",
#         "iam:ListServerCertificates",
#         "cognito-idp:DescribeUserPoolClient",
#         "tag:GetResources",
#         "tag:TagResources",
#     ]

#     resources = [
#       "*"
#     ]

#   }
# }

# data "aws_iam_policy_document" "albingresscontroller5" {
#   statement {
    
#     effect = "Allow"

#     actions = [
#         "waf-regional:GetWebACLForResource",
#         "waf-regional:GetWebACL",
#         "waf-regional:AssociateWebACL",
#         "waf-regional:DisassociateWebACL",
#         "waf:GetWebACL",
#         "wafv2:GetWebACL",
#         "wafv2:GetWebACLForResource",
#         "wafv2:AssociateWebACL",
#         "wafv2:DisassociateWebACL",
#         "shield:DescribeProtection",
#         "shield:GetSubscriptionState",
#         "shield:DeleteProtection",
#         "shield:CreateProtection",
#         "shield:DescribeSubscription",
#         "shield:ListProtections"
#     ]

#     resources = [
#       "*"
#     ]

#   }
# }
