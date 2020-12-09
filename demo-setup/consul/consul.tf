provider "consul" {
  address = "127.0.0.1:8500"
  datacenter = "dc1"
}

# Create KV for Intersight Compute and Security

resource "consul_keys" "compute" {

  key {
    path  = "intersight_compute/configuration/"
    value = ""
  }

  key {
    path  = "intersight_compute/state/"
    value = ""
  }
}

resource "consul_keys" "security" {

  key {
    path  = "intersight_security/configuration/"
    value = ""
  }

  key {
    path  = "intersight_security/state/"
    value = ""
  }
}

# Create policies to allow the Intersight Compute role to read and write the compute KV

resource "consul_acl_policy" "compute" {
  name = "intersight_compute"
  rules = <<-RULE
    key_prefix "intersight_compute" {
      policy = "write"
    }

    session_prefix "" {
      policy = "write"
    }
    RULE
}

# Create policies to allow the Intersight Compute role to read and write the security KV and just read the compute state

resource "consul_acl_policy" "security" {
  name = "intersight_security"
  rules = <<-RULE
    key_prefix "intersight_security" {
      policy = "write"
    }

    key_prefix "intersight_compute/state" {
      policy = "read"
    }

    session_prefix "" {
      policy = "write"
    }

    RULE
}

resource "consul_acl_token" "compute_admin" {
  description = "Token for the Intersight Compute Admin"
  policies = [consul_acl_policy.compute.name]
}

resource "consul_acl_token" "security_admin" {
  description = "Token for Intersight Security Admin"
  policies = [consul_acl_policy.security.name]
}

## OUTPUTS

output "intersight_compute_user_accessor_id" {
  value = consul_acl_token.compute_admin.id
}

output "intersight_security_user_accessor_id" {
  value = consul_acl_token.security_admin.id
}
