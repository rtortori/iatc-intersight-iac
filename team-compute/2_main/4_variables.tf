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

# Passed by Jenkins, defaults to 1
variable "jobid" {
    default = 1
}

# Localize the remote configuration living in Consul
locals {
  server_profile_action = jsondecode(data.consul_keys.compute.var.intersight_compute)["server_profile_action"]
  bios_terminal_type =  jsondecode(data.consul_keys.compute.var.intersight_compute)["bios_terminal_type"]     
  ntp_servers =  jsondecode(data.consul_keys.compute.var.intersight_compute)["ntp_servers"]    
  ntp_timezone =  jsondecode(data.consul_keys.compute.var.intersight_compute)["ntp_timezone"]     
  syslog_min_severity = jsondecode(data.consul_keys.compute.var.intersight_compute)["syslog_min_severity"]      
  syslog_remote_client = jsondecode(data.consul_keys.compute.var.intersight_compute)["syslog_remote_client"]     
  syslog_remote_client_port = jsondecode(data.consul_keys.compute.var.intersight_compute)["syslog_remote_client_port"]        
}