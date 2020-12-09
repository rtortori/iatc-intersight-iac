#######################
# INTERSIGHT POLICIES #
#######################

resource "intersight_ssh_policy" "ssh_policy_1" {
  name        = "${var.resource_prefix}_ssh_policy_jobid_${var.jobid}"
  description = "Created by Terraform"
  enabled     = true

  port    = local.ssh_port
  timeout = local.ssh_timeout

  profiles {
    moid        = data.terraform_remote_state.compute.outputs.my_server_profile.id
    object_type = data.terraform_remote_state.compute.outputs.my_server_profile.object_type
  }
  
  organization {
    object_type = "organization.Organization"
    moid = data.intersight_organization_organization.org.moid
  }

  tags {
    key   = "Project"
    value = "Rick Terraform Tests"
  }

  tags {
    key   = "Environment"
    value = terraform.workspace
  }
}
