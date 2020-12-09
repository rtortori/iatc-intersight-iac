#############
# VARIABLES #
#############

variable "github_token" {
    default = "my_gh_token"
}

variable "visibility" {
    default = "private"
}

variable "compute_repository_name" {
    default = "intersight_iac_demo_compute"
}

variable "security_repository_name" {
    default = "intersight_iac_demo_security"
}

variable "repository_desc" {
    default = "Intersight Infrastructure-as-Code Demo"
}