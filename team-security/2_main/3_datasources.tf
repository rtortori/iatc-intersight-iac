################
# DATA SOURCES #
################

# Fetch remote state from Consul
data "terraform_remote_state" "compute" {
  backend = "consul"

  config = {
    address = var.consul_address
    scheme = var.consul_scheme
    path     = terraform.workspace == "default" ? "intersight_compute/state/current-state" : "intersight_compute/state/current-state-env:${terraform.workspace}"
    access_token = data.vault_generic_secret.consul.data.token
  }
}

# Fetch the ordanization data so we can extract the MOID
data "intersight_organization_organization" "org" {
    name = var.organization
}

# Ask Vault to generate a secret to access Consul with the compute policy
data "vault_generic_secret" "consul" {
  path = "consul/creds/intersight_security"
}

# Read intersight api_key from Vault
data "vault_generic_secret" "intersight_api_key" {
  path = "intersight/credentials/api_key"
}

# Fetch security configuration
data "consul_keys" "security" {
  key {
      name = "intersight_security"
      path = "intersight_security/configuration/security_config"
  }
}