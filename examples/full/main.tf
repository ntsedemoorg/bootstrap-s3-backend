module "example" {
  source                  = "../.."
  iam_principals          = [aws_iam_user.example.arn]
  state_bucket_kms_key_id = aws_kms_key.example.arn
  logs_bucket_kms_key_id  = aws_kms_key.example.arn
  region_name             = data.aws_region.current.name
}

#checkov:skip=CKV_AWS_273:Example resource
resource "aws_iam_user" "example" {
  name = "example"
}

#checkov:skip=CKV_AWS_273:Example resource
resource "aws_kms_key" "example" {
  description             = "Key used to encrypt both the state and logs buckets"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

data "aws_region" "current" {}