variable "enable_s3_bucket_versioning" {
  description = "Whether or not to enable bucket versioning on the state S3 bucket"
  type        = bool
  default     = true
}

variable "iam_principals" {
  description = "A list of IAM user or role ARNs that will have access to the state S3 bucket"
  type        = list(string)
}

variable "state_bucket_kms_key_id" {
  description = "The KMS key ID used to encrypt the S3 state bucket. Uses AWS-managed key if not specified."
  type        = string
  default     = ""
}

variable "logs_bucket_kms_key_id" {
  description = "The KMS key ID used to encrypt the S3 state logs bucket. Uses AWS-managed key if not specified."
  type        = string
  default     = ""
}

variable "region_name" {
  description = "Name of the region that the state file is responsible for"
  type        = string
}