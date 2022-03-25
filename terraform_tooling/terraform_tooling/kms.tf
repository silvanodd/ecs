resource "aws_kms_key" "my_resource" {
  description             = module.label.id
  deletion_window_in_days = 7

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "TenantAccountAccess",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${aws_iam_role.codebuild_service_role.arn}",
                    "arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role",
                    "arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
                    ]
            },
            "Action": [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:CreateGrant",
              "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}