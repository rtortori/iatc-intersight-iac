################
# DATA SOURCES #
################

# Fetch target physical server details to we can extract the MOID
data "intersight_compute_rack_unit" "carlton" {
    mgmt_ip_address = "192.168.30.22"
}

# Fetch the ordanization data so we can extract the MOID
data "intersight_organization_organization" "org" {
    name = var.organization
}

# Ask Vault to generate a secret to access Consul with the compute policy
data "vault_generic_secret" "consul" {
  path = "consul/creds/intersight_compute"
}

# Read intersight api_key from Vault
data "vault_generic_secret" "intersight_api_key" {
  path = "intersight/credentials/api_key"
}

# Fetch Compute Configurations
data "consul_keys" "compute" {
  key {
      name = "intersight_compute"
      path = "intersight_compute/configuration/compute_config"
  }
}