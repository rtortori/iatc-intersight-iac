# Jenkins Terraform Resources

resource jenkins_job compute_demo_pipeline {
  name     = "intersight_iac_demo_compute"
  template = file("./job.xml")
  depends_on = [ github_repository.compute_repository ]

  parameters = {
    description = "Intersight IaC Demo Pipeline"
    url = github_repository.compute_repository.http_clone_url
    credentials = "GitHub_Credentials"
  }
}

resource jenkins_job security_demo_pipeline {
  name     = "intersight_iac_demo_security"
  template = file("./job.xml")
  depends_on = [ github_repository.security_repository ]

  parameters = {
    description = "Intersight IaC Demo Pipeline"
    url = github_repository.security_repository.http_clone_url
    credentials = "GitHub_Credentials"
  }
}
