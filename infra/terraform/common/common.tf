provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 0.12.4"
}

variable "region" {
}

variable "remote_state_bucket" {
}

variable "cluster_name" {
  default = "eks-ci-cluster"
}
