output "instance_name" {
  description = "The name of the created VM instance."
  value       = google_compute_instance.jenkins.name
}

output "instance_private_ip" {
  description = "The internal IP address of the VM instance."
  value       = google_compute_instance.jenkins.network_interface[0].network_ip
}

output "instance_public_ip" {
  description = "The public (external) IP address of the VM instance."
  value       = google_compute_address.instance_ip_external.address
}

output "instance_zone" {
  description = "The zone where the VM instance is located."
  value       = google_compute_instance.jenkins.zone
}

output "instance_status" {
  description = "The current status of the VM instance."
  value       = google_compute_instance.jenkins.desired_status
}