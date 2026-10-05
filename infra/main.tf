data "aws_caller_identity" "current" {}

locals {
  # Account ID suffix keeps the bucket name globally unique.
  bucket_name = "${var.project}-site-${data.aws_caller_identity.current.account_id}"
  cf          = var.enable_cloudfront ? 1 : 0
  website     = var.enable_cloudfront ? 0 : 1
}

# ---------------------------------------------------------------------------
# S3 bucket
#   enable_cloudfront = true  -> private bucket, only CloudFront can read it
#   enable_cloudfront = false -> public S3 static website (HTTP only)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = var.enable_cloudfront
  restrict_public_buckets = var.enable_cloudfront
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_website_configuration" "site" {
  count  = local.website
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  # SPA fallback: unknown paths return index.html.
  error_document {
    key = "index.html"
  }
}

# ---------------------------------------------------------------------------
# CloudFront with Origin Access Control
# ---------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "site" {
  count                             = local.cf
  name                              = "${var.project}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# AWS managed cache policy "CachingOptimized"
data "aws_cloudfront_cache_policy" "optimized" {
  count = local.cf
  name  = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "site" {
  count               = local.cf
  enabled             = true
  comment             = "${var.project} SPA"
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # includes India edge locations

  origin {
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id                = "s3-site"
    origin_access_control_id = aws_cloudfront_origin_access_control.site[0].id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = data.aws_cloudfront_cache_policy.optimized[0].id
    compress               = true
  }

  # SPA fallback: unknown paths return index.html so client routing works.
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# ---------------------------------------------------------------------------
# Bucket policy
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "bucket_cloudfront" {
  count = local.cf

  statement {
    sid       = "AllowCloudFrontRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site[0].arn]
    }
  }
}

data "aws_iam_policy_document" "bucket_public" {
  count = local.website

  statement {
    sid       = "PublicRead"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = (var.enable_cloudfront
    ? data.aws_iam_policy_document.bucket_cloudfront[0].json
  : data.aws_iam_policy_document.bucket_public[0].json)
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# ---------------------------------------------------------------------------
# Least-privilege IAM user for GitHub Actions
# (create its access key with the AWS CLI; see README)
# ---------------------------------------------------------------------------
resource "aws_iam_user" "deployer" {
  name = "${var.project}-github-deployer"
}

data "aws_iam_policy_document" "deployer" {
  statement {
    sid       = "ListBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }

  statement {
    sid       = "WriteObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }

  dynamic "statement" {
    for_each = aws_cloudfront_distribution.site
    content {
      sid       = "InvalidateCache"
      actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
      resources = [statement.value.arn]
    }
  }
}

resource "aws_iam_user_policy" "deployer" {
  name   = "${var.project}-deploy"
  user   = aws_iam_user.deployer.name
  policy = data.aws_iam_policy_document.deployer.json
}
