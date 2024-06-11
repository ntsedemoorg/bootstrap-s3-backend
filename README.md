# Bootstrapping AWS accounts for Terraform backend

This Terraform module bootstraps an AWS account by creating an S3 bucket and a DynamoDB table, which are essential components for storing remote Terraform state files. Access to the S3 bucket is restricted to IAM users and roles passed in as `iam_principals` input variable list.

🐔🥚

## Usage

```hcl
module "bootstrap" {
  source = "./"

  region               = "eu-west-1"
  iam_principals       = ["arn:aws:iam::123456789012:user/example-user"]
}
```

## Assumptions and notes

- `<account id>-<region name>-state` - This bucket is to store the state files.
- `<account id>-<region name>-state-logs` - This bucket stores the access logs of the first bucket
- The state file for the S3 backend resources (S3 bucket, DynamoDB table and other ancillaries) is stored in `s3://11111111111111111-eu-west-1-state/s3-backend-state/terraform.tfstate`
- When running `terraform init` in the Terraform code base that will have its state stored in these buckets, `backend-config` flags will need adding. E.g.
```bash
terraform init \  
  -backend-config=dynamodb_table=<region name>-state-locks \
  -backend-config=bucket=<account id>-<region name>-state \
  -backend-config=key=<environment name>/<module name>/terraform.tfstate
```
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.52.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.52.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.terraform_locks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_lifecycle_configuration.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_ownership_controls.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.terraform_state_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.terraform_state_bucket_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_s3_bucket_versioning"></a> [enable\_s3\_bucket\_versioning](#input\_enable\_s3\_bucket\_versioning) | Whether or not to enable bucket versioning on the state S3 bucket | `bool` | `true` | no |
| <a name="input_iam_principals"></a> [iam\_principals](#input\_iam\_principals) | A list of IAM user or role ARNs that will have access to the state S3 bucket | `list(string)` | n/a | yes |
| <a name="input_logs_bucket_kms_key_id"></a> [logs\_bucket\_kms\_key\_id](#input\_logs\_bucket\_kms\_key\_id) | The KMS key ID used to encrypt the S3 state logs bucket. Uses AWS-managed key if not specified. | `string` | `""` | no |
| <a name="input_region_name"></a> [region\_name](#input\_region\_name) | Name of the region that the state file is responsible for | `string` | n/a | yes |
| <a name="input_state_bucket_kms_key_id"></a> [state\_bucket\_kms\_key\_id](#input\_state\_bucket\_kms\_key\_id) | The KMS key ID used to encrypt the S3 state bucket. Uses AWS-managed key if not specified. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table_arn"></a> [dynamodb\_table\_arn](#output\_dynamodb\_table\_arn) | The ARN of the DynamoDB table |
| <a name="output_s3_logging_bucket_arn"></a> [s3\_logging\_bucket\_arn](#output\_s3\_logging\_bucket\_arn) | The ARN of the S3 logging bucket |
| <a name="output_s3_state_bucket_arn"></a> [s3\_state\_bucket\_arn](#output\_s3\_state\_bucket\_arn) | The ARN of the S3 bucket |
<!-- END_TF_DOCS -->