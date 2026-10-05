variable "region" {
  description = "AWS region for the S3 bucket"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "aws-devops-poc"
}
