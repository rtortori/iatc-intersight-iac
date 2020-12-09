#############
# VARIABLES #
#############

variable "secret_keyfile_name" {}
variable "organization" {}
variable "resource_prefix" {}
variable "consul_address" {}
variable "consul_datacenter" {}
variable "vault_address" {}
variable "vault_token" {}
variable "consul_scheme" {}

# Passed by Jenkins, defaults to 1
variable "jobid" {
    default = 1
}

# Localize the remote configuration living in Consul
locals {
  ssh_port = jsondecode(data.consul_keys.security.var.intersight_security)["ssh_port"] 
  ssh_timeout = jsondecode(data.consul_keys.security.var.intersight_security)["ssh_timeout"]       
}