#######################
# INTERSIGHT POLICIES #
#######################


# BIOS Policy

resource "intersight_bios_policy" "bios_policy_1" {
  name          = "${var.resource_prefix}_bios_policy_jobid_${var.jobid}"
  description   = "Created by Terraform"

  # Policy attributes
  terminal_type = local.bios_terminal_type
  memory_size_limit = "platform-default"
  partial_mirror_percent = "platform-default"
  partial_mirror_value1 = "platform-default"
  partial_mirror_value2 = "platform-default"
  partial_mirror_value3 = "platform-default"
  partial_mirror_value4 = "platform-default"
  patrol_scrub_duration = "platform-default"

  depends_on = [ intersight_server_profile.my_server_profile ]

  profiles {
    moid        = intersight_server_profile.my_server_profile.id
    object_type = intersight_server_profile.my_server_profile.object_type
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

# NTP Policy

resource "intersight_ntp_policy" "ntp_pol_1" {
  name        = "${var.resource_prefix}_ntp_policy_jobid_${var.jobid}"
  description   = "Created by Terraform"
  enabled     = true

  depends_on = [ intersight_server_profile.my_server_profile ]

  #ntp_servers = [
  #  "ntp.esl.cisco.com",
  #  "time-a-g.nist.gov",
  #  "time-b-g.nist.gov"
  #]

  ntp_servers = local.ntp_servers
  timezone = local.ntp_timezone
  
  profiles {
    moid        = intersight_server_profile.my_server_profile.id
    object_type = intersight_server_profile.my_server_profile.object_type
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

# Syslog Policy

resource "intersight_syslog_policy" "syslog_policy_1" {
  name        = "${var.resource_prefix}_syslog_policy_jobid_${var.jobid}"
  description   = "Created by Terraform"

  depends_on = [ intersight_server_profile.my_server_profile ]
  

  local_clients {
    min_severity = local.syslog_min_severity
    object_type  = "syslog.LocalFileLoggingClient"
  }
  remote_clients {
    enabled      = true
    hostname     = local.syslog_remote_client
    port         = local.syslog_remote_client_port
    protocol     = "tcp"
    min_severity = local.syslog_min_severity
    object_type  = "syslog.RemoteLoggingClient"
  }
  
  profiles {
    moid        = intersight_server_profile.my_server_profile.id
    object_type = intersight_server_profile.my_server_profile.object_type
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