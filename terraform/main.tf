resource "google_compute_address" "instance_ip_external" {
    name    = var.instance_name
    project = var.project_id
    region  = var.region
    #global  = true
    network_tier = var.network_tier
    address_type = "EXTERNAL"
}

resource "google_compute_instance" "jenkins" {
    name    = var.instance_name
    project = var.project_id
    zone    = var.zone
    machine_type = format("custom-%d-%d", var.custom_vcpus, var.custom_memory_gb * 1024)
    desired_status = var.vm_desired_status

    boot_disk {
        initialize_params {
            image = var.boot_disk_image
            size  = var.boot_disk_size
        }
    }
    network_interface {
        network = "default"
        access_config {
            nat_ip = google_compute_address.instance_ip_external.address
            network_tier = google_compute_address.instance_ip_external.network_tier
        }
    }
}


