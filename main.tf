resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  acl    = var.acl
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

  versioning {
    enabled = var.versioning
  }
  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
      days = 60
    }
  }

  lifecycle {
    prevent_destroy = false # This needs to be changed once the application is in good state
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    sid = "AllowCloudFront"
    actions = ["s3:GetObject", "s3:ListBucket"]

    resources = [
      "${aws_s3_bucket.this.arn}",
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "AWS"
      identifiers = ["${var.OIA_arn}"] # This arn can be changed to any arn like ecs task role arn when needed. 
    }
  }
  statement {
    sid = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    condition {
      test = "Bool"
      values = [
        "false",
      ]
      variable = "aws:SecureTransport"
    }
    effect = "Deny"
    principals {
      identifiers = [
        "*",
      ]
      type = "AWS"
    }
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = var.acl == "private" ? true : false
  block_public_policy     = var.acl == "private" ? true : false
  ignore_public_acls      = var.acl == "private" ? true : false
  restrict_public_buckets = var.acl == "private" ? true : false
}

output "bucket_domain_name" {
  value = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}
