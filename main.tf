terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  website {
    index_document = "index.html"
  }

  tags = {
    Project = "TerraformStaticWebsite"
  }

}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*",
      Action = ["s3:GetObject"],
      Resource = ["${aws_s3_bucket.website_bucket.arn}/*"]
    }]
  })
}

resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_object" "static_files" {
  for_each = fileset("website", "**")

  bucket       = aws_s3_bucket.website_bucket.id
  key          = each.value
  source       = "website/${each.value}"
  content_type = lookup(
    {
      "html" = "text/html"
      "htm"  = "text/html"
      "jpg"  = "image/jpeg"
      "jpeg" = "image/jpeg"
      "png"  = "image/png"
      "gif"  = "image/gif"
      "css"  = "text/css"
      "js"   = "application/javascript"
      "svg"  = "image/svg+xml"
    },
    lower(trimspace(element(split(".", each.value), length(split(".", each.value)) - 1))),
    "application/octet-stream"
  )
}
