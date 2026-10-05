output "bucket_name" {
  description = "GitHub secret S3_BUCKET"
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  description = "GitHub secret CLOUDFRONT_DISTRIBUTION_ID"
  value       = aws_cloudfront_distribution.site.id
}

output "website_url" {
  value = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "deployer_user" {
  description = "IAM user whose access key goes into GitHub secrets"
  value       = aws_iam_user.deployer.name
}
