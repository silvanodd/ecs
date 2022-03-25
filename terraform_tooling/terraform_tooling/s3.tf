resource "aws_s3_bucket" "my_resource" {
  bucket = join("-", [module.label.id, "tooling"])
 
}

resource "aws_s3_bucket_server_side_encryption_configuration" "my_resource" {
  bucket = aws_s3_bucket.my_resource.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_resource.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "my_resource" {
  bucket = aws_s3_bucket.my_resource.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "Policy1648138606291",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.label.id}_codebuild_service_role",
                    "arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role",
                    "arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
                    ]
            },
            "Action": "s3:*",
            "Resource": "${aws_s3_bucket.my_resource.arn}"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.dev_account_id}:role/${module.label.id}_code_pipeline_cross_account_role",
                    "arn:aws:iam::${var.prod_account_id}:role/${module.label.id}_code_pipeline_cross_account_role"
                    ]
            },
            "Action": "s3:*",
            "Resource": "${aws_s3_bucket.my_resource.arn}/*"
        }
    ]
}
POLICY 
}


