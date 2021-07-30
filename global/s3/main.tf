provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "tf-state" {
  bucket = "wintershine-tf-state"

  lifecycle {
    prevent_destroy = true
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "tf-locks" {
  name     = "wintershine-tf-locks"
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  read_capacity  = 2
  write_capacity = 2
}