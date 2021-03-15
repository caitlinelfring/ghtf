terraform {
  required_version = ">= 0.12, < 0.14"
}

provider "github" {
  token   = var.github_token
  owner   = var.github_owner
  version = "~> 4.5.1"
}

variable "github_token" {
  type = string
  // requires terraform 0.14
  // sensitive = true
}

variable "github_owner" {
  type = string
}
