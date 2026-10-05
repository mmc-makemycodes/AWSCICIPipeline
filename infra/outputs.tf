output "bucket_name" {
  description = "GitHub secret S3_BUCKET"
  value       = aws_s3_bucket.site.bucket
}

output "website_url" {
  value = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

output "deployer_user" {
  description = "IAM user whose access key goes into GitHub secrets"
  value       = aws_iam_user.deployer.name
}
