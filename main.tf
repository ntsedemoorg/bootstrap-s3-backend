data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region_name}-state"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.enable_s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    #checkov:skip=CKV2_AWS_67:Using a CMK is decided by the caller of the module and creating one is out-of-scope here.
    apply_server_side_encryption_by_default {
      sse_algorithm     = length(var.state_bucket_kms_key_id) > 0 ? "aws:kms" : "AES256"
      kms_master_key_id = length(var.state_bucket_kms_key_id) > 0 ? var.state_bucket_kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

data "aws_iam_policy_document" "terraform_state_bucket" {
  statement {
    sid = "allow-user-list-access"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = var.iam_principals
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]
  }

  statement {
    sid = "require-tls"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.terraform_state.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  policy = data.aws_iam_policy_document.terraform_state_bucket.json
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_bucket_logs.id
  target_prefix = "log/"
}

resource "aws_dynamodb_table" "terraform_locks" {
  # checkov:skip=CKV_AWS_28:The state lock table is ephemeral and doesn't need PITR.
  # checkov:skip=CKV_AWS_119:No data is contained in this table. Encrypting with CMK is unnecessary.
  name         = "${var.region_name}-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }
}

resource "aws_s3_bucket" "terraform_state_bucket_logs" {
  bucket = "${data.aws_caller_identity.current.account_id}-${var.region_name}-state-logs"
}

# TODO: Find policy on how long logs should be kept for and change this.
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_bucket_logs" {
  bucket = aws_s3_bucket.terraform_state_bucket_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"

    expiration {
      days                         = 90
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "terraform_state_bucket_logs" {
  bucket = aws_s3_bucket.terraform_state_bucket_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "terraform_state_bucket_logs" {
  bucket = aws_s3_bucket.terraform_state_bucket_logs.id
  policy = data.aws_iam_policy_document.terraform_state_bucket_logs.json
}

data "aws_iam_policy_document" "terraform_state_bucket_logs" {
  statement {
    sid = "require-tls"

    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      "${aws_s3_bucket.terraform_state_bucket_logs.arn}/*"
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_bucket_logs" {
  bucket                  = aws_s3_bucket.terraform_state_bucket_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_logs" {
  bucket = aws_s3_bucket.terraform_state_bucket_logs.id

  rule {
    #checkov:skip=CKV2_AWS_67:Using a CMK is decided by the caller of the module and creating one is out-of-scope here.
    apply_server_side_encryption_by_default {
      sse_algorithm     = length(var.logs_bucket_kms_key_id) > 0 ? "aws:kms" : "AES256"
      kms_master_key_id = length(var.logs_bucket_kms_key_id) > 0 ? var.logs_bucket_kms_key_id : null
    }
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_bucket_logs" {
  count  = var.enable_s3_bucket_versioning ? 1 : 0
  bucket = aws_s3_bucket.terraform_state_bucket_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}
