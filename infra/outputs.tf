output "bucket_name" {
  description = "GitHub secret S3_BUCKET"
  value       = aws_s3_bucket.site.bucket
}

output "cloudfront_distribution_id" {
  description = "GitHub secret CLOUDFRONT_DISTRIBUTION_ID (empty when CloudFront is disabled)"
  value       = try(aws_cloudfront_distribution.site[0].id, "")
}

output "website_url" {
  value = (var.enable_cloudfront
    ? "https://${aws_cloudfront_distribution.site[0].domain_name}"
  : "http://${aws_s3_bucket_website_configuration.site[0].website_endpoint}")
}

output "deployer_user" {
  description = "IAM user whose access key goes into GitHub secrets"
  value       = aws_iam_user.deployer.name
}
