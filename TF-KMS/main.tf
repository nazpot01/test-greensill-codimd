resource "aws_kms_key" "default" {
  count                   = var.enabled == true ? 1 : 0
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
 # policy                  = ""
  policy                  = var.policy
  tags                    = merge({ "Name" = format("%s-%s-kms-%s", var.namespace, var.environment, var.project) }, { "Project" = var.project}, var.tags)
  description             = var.description
}

resource "aws_kms_alias" "default" {
  count         = var.enabled == true ? 1 : 0
  name          = coalesce(var.alias, format("alias/%v", format("%s-%s-kms-%s", var.namespace, var.environment, var.project)))
  target_key_id = join("", aws_kms_key.default.*.id)
}
