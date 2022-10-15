variable "aws_region" {
  default     = "us-east-1"
  description = "AWS deployment region"
}

variable "app_name" {
  default     = "s3-lambda-remove-exif"
  description = "Terraform application name"
}
