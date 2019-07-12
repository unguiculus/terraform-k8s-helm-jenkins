data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket
    key    = "networking"
    region = var.region
  }
}
