##############################
# INTERSIGHT SERVER PROFILES #
##############################

resource "intersight_server_profile" "my_server_profile" {
  name        = "${var.resource_prefix}_my_server_profile_${terraform.workspace}_jobid_${var.jobid}"
  description = "Created by Terraform"
  action = local.server_profile_action

  assigned_server {
    moid        = data.intersight_compute_rack_unit.carlton.moid
    object_type = data.intersight_compute_rack_unit.carlton.object_type
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