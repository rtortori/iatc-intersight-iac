# GitHub Terraform Resources

resource "github_repository" "compute_repository" {
  name        = var.compute_repository_name
  description = var.repository_desc
  visibility  = var.visibility
}

resource "github_repository" "security_repository" {
  name        = var.security_repository_name
  description = var.repository_desc
  visibility  = var.visibility
}