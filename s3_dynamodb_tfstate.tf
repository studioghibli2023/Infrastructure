
###########################################  DynamoDB Table ##########################################

resource "aws_dynamodb_table" "tf_lock_table-new" {
  name           = "tf-lock-table-new"
  billing_mode   = "PAY_PER_REQUEST"  # or "PROVISIONED" if you want to provision throughput capacity
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"  # Assuming LockID is a string, use "N" for number
  }

  tags = {
    Name = "tf-lock-table-new"
    # Add more tags as needed
  }
}

###########################################  S3 Bucket  ##########################################


resource "aws_s3_bucket" "terraform_remote_state_file_new" {
  bucket = "terraform-remote-state-file-new"
  acl    = "private"  # Set the ACL (Access Control List) according to your requirements

  # Optionally, you can specify additional configurations like versioning, encryption, etc.
  versioning {
    enabled = true
  }

  # Add more configurations as needed
}