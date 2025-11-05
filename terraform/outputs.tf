output "jenkins_public_dns" {
  description = "Public DNS for the Jenkins server"
  value       = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  description = "Jenkins HTTP URL"
  value       = "http://${aws_instance.jenkins.public_dns}:8080"
}

output "jenkins_admin_username" {
  value       = var.jenkins_admin_username
  description = "Initial Jenkins admin username"
}

output "jenkins_admin_password_note" {
  value       = "The password is in TFC variable jenkins_admin_password (sensitive)."
  description = "Where to find password"
}
