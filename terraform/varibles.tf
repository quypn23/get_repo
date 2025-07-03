variable project_id {
  type        = string
  default     = "midyear-tempo-464707-q5" #LAB-QuyPN23
  description = "The GCP Project ID where resources will be created"
}

variable region {
  type        = string
  default     = "asia-east2"
  description = "The GCP Region HK"
}

variable zone {
  type        = string
  default     = "asia-east2-c"
  description = "The GCP Zone HK"
}

variable instance_name {
    type    = string
    description = "Instance Name"
    default = "jenkins" # Input name instance
}

variable machine_type {
    type    = string
    description = "Machine Type -> Use template GCP"
    default = "e2-standard-2"
}

variable "custom_vcpus" {
  description = "Number of custom vCPUs for the VM."
  type        = number
  default     = 2 
  validation {
    condition     = var.custom_vcpus >= 1 && var.custom_vcpus <= 32 && var.custom_vcpus % 2 == 0
    error_message = "Custom vCPUs must be an even number between 1 and 32."
  }
}

variable "custom_memory_gb" {
  description = "Amount of custom memory in GB for the VM."
  type        = number
  default     = 4 
  validation {
    condition     = var.custom_memory_gb >= 1 && var.custom_memory_gb <= 16
    error_message = "Custom memory must be between 1GB and 16GB."
  }
}

variable "boot_disk_image" {
    description = "Select OS release for VM"
    type    = string
    default = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size" {
    description = "Size of boot disk in GB"
    type    = number
    default = 40
}

variable "network_tier" {
    type    = string
    default = "STANDARD"
}

# Start, Stop, Suspend
variable "vm_desired_status" {
  description = "Desired status of the VM instance (RUNNING, TERMINATED, SUSPENDED)."
  type        = string
  default     = "TERMINATED" # Mặc định là chạy
  validation {
    condition     = contains(["RUNNING", "TERMINATED", "SUSPENDED"], upper(var.vm_desired_status))
    error_message = "VM desired status must be RUNNING, TERMINATED, or SUSPENDED."
  }
}
