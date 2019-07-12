resource "aws_dynamodb_table" "terraform-state-lock" {
  name           = "${var.remote_state_bucket}-lock"
  hash_key       = "LockID"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}
