# data "aws_caller_identity" "current" {}
# locals {
    
#     policy_lambda = <<POLICY
# {
#   "Id": "key-consolepolicy-3",
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "Enable IAM User Permissions",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": [
#           "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         ]
#       },
#       "Action": "kms:*",
#       "Resource": "*"
#     },
#     {
#       "Sid": "Allow use of the key",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": [
#           "${aws_iam_role.lambda_rotation.arn}"
#         ]
#       },
#       "Action": [
#         "kms:Encrypt",
#         "kms:Decrypt",
#         "kms:ReEncrypt*",
#         "kms:GenerateDataKey*",
#         "kms:DescribeKey"
#       ],
#       "Resource": "*"
#     },
#     {
#       "Sid": "Allow attachment of persistent resources",
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": [
#           "${aws_iam_role.lambda_rotation.arn}"
#         ]
#       },
#       "Action": [
#         "kms:CreateGrant",
#         "kms:ListGrants",
#         "kms:RevokeGrant"
#       ],
#       "Resource": "*",
#       "Condition": {
#         "Bool": {
#           "kms:GrantIsForAWSResource": "true"
#         }
#       }
#     }
#   ]
# }
# POLICY

# policy_kms = var.policy == "" ? var.policy : local.policy_lambda
# } 