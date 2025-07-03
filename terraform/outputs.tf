# output "instance_name" {
#   description = "The name of the created VM instance."
#   value       = google_compute_instance.jenkins.name
# }

# output "instance_private_ip" {
#   description = "The internal IP address of the VM instance."
#   value       = google_compute_instance.jenkins.network_interface[0].network_ip
# }

# output "instance_public_ip" {
#   description = "The public (external) IP address of the VM instance."
#   value       = google_compute_address.instance_ip_external.address
# }

# output "instance_zone" {
#   description = "The zone where the VM instance is located."
#   value       = google_compute_instance.jenkins.zone
# }

# output "instance_status" {
#   description = "The current status of the VM instance."
#   value       = google_compute_instance.jenkins.desired_status
# }

# outputs.tf

output "vm_details" {
  description = "Details of all created VM instances."
  value = {
    for k, v in google_compute_instance.default : k => { # Lặp qua từng instance VM
      name        = v.name
      private_ip  = v.network_interface[0].network_ip
      public_ip   = google_compute_address.vm_static_ip[k].address # Lấy IP tương ứng
    #   ssh_command = "gcloud compute ssh ${v.name} --zone=${var.zone} --project=${var.project_id}"
      status      = v.current_status
    }
  }
}