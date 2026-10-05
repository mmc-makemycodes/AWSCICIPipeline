variable "region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "ap-south-1"
}

variable "enable_cloudfront" {
  description = "true = private bucket behind CloudFront (HTTPS). false = public S3 website (HTTP). CloudFront requires a verified AWS account."
  type        = bool
  default     = false
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "aws-devops-poc"
}
