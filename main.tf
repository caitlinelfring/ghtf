provider "github" {
  token = var.github_token
  owner = var.github_owner
}

variable "github_token" {
  type = string
  // requires terraform 0.14
  // sensitive = true
}

variable "github_owner" {
  type = string
}
