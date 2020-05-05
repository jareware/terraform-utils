locals {
  reprovision_trigger = jsonencode({
    docker_compose_version      = var.docker_compose_version
    docker_compose_env          = var.docker_compose_env
    docker_compose_yml          = var.docker_compose_yml
    docker_compose_override_yml = var.docker_compose_override_yml
    docker_compose_up_command   = var.docker_compose_up_command
  })
}

output "reprovision_trigger" {
  description = "Stringified version of all docker-compose configuration used for this host; can be used as the `reprovision_trigger` input to an `aws_ec2_ebs_docker_host` module"
  value       = local.reprovision_trigger
}
