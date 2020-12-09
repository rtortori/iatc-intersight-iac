################################################################################
# Create Intersight Certificate file based from the secret definition in Vault #
################################################################################

# Init Vault Provider
provider "vault" {
  address = var.vault_address
  token = var.vault_token
}

# Init variables
variable "secret_keyfile_name" {}
variable "vault_address" {}
variable "vault_token" {}
variable "consul_address" {}
variable "consul_scheme" {}

# Read intersight private certificate from Vault
data "vault_generic_secret" "intersight" {
  path = "intersight/credentials/cert"
}

# Ask Vault to generate a secret to access Consul with the compute policy
data "vault_generic_secret" "consul" {
  path = "consul/creds/intersight_compute"
}

# Create local copy of certificate
resource "local_file" "is_cert" {
    content     = data.vault_generic_secret.intersight.data.cert
    filename = "../2_main/${var.secret_keyfile_name}"
}

# Create backend TF file
resource "local_file" "backend_tf_file" {
    filename = "../2_main/2_backend.tf"
    content = <<-EOT
    terraform {
        backend "consul" {
            address = "${var.consul_address}"
            scheme = "${var.consul_scheme}"
            access_token = "${data.vault_generic_secret.consul.data.token}"
        }
    }
    EOT
}