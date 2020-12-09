# Init Github Repository

terraform {
  required_providers {
    jenkins = {
      source  = "overmike/jenkins"
      version = "0.6.1"
    }
  }
}

provider jenkins {
}

provider "github" {
  version = "4.1.0"
  token   = var.github_token
}