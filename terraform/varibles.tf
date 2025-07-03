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
  default     = "RUNNING" # Mặc định là chạy
  validation {
    condition     = contains(["RUNNING", "TERMINATED", "SUSPENDED"], upper(var.vm_desired_status))
    error_message = "VM desired status must be RUNNING, TERMINATED, or SUSPENDED."
  }
}

# Biến mới để định nghĩa cấu hình cho từng VM cụ thể
variable "vm_configs" {
  description = "A map of specific configurations for each VM instance. Keys are unique identifiers."
  type = map(object({
    # Tên của VM. Đây là trường bắt buộc để xác định từng VM.
    name              = string
    # Các thuộc tính này là tùy chọn. Nếu không được cung cấp, nó sẽ dùng biến mặc định global
    machine_type      = optional(string) # Ví dụ: "e2-standard-4" nếu muốn khác default
    custom_vcpus      = optional(number) # Ví dụ: 4 nếu muốn khác default
    custom_memory_gb  = optional(number) # Ví dụ: 8 nếu muốn khác default
    boot_disk_image   = optional(string) # Ví dụ: "debian-cloud/debian-12" nếu muốn khác default
    boot_disk_size    = optional(number) # Ví dụ: 60 nếu muốn khác default
    startup_script    = optional(string, "") # Script khởi động riêng cho VM này
    network_tier      = optional(string) # Ví dụ: "STANDARD" nếu muốn khác default)
    #tags              = optional(list(string), ["ssh"]) # Các tag riêng
  }))
  default = {
    "r-01" = {
      name              = "r-01"
      # Các thuộc tính khác sẽ lấy từ các biến mặc định global (ví dụ: e2-standard-2, ubuntu-2204, 40GB disk)
    #   startup_script    = <<-EOT
    #                       #!/bin/bash
    #                       sudo apt-get update && sudo apt-get install -y nginx
    #                       echo "<h1>Hello from Web Server 01!</h1>" | sudo tee /var/www/html/index.html
    #                       EOT
    #   tags              = ["http-server", "ssh"]
    },
    "t-01" = {
      name              = "t-01"
    #   custom_vcpus      = 2
    #   custom_memory_gb  = 8
    #   boot_disk_size    = 80
    #   startup_script    = <<-EOT
    #                       #!/bin/bash
    #                       echo "Configuring Jenkins agent..."
    #                       # Commands to setup Jenkins agent
    #                       EOT
    #   tags              = ["ssh", "jenkins-agent"]
    }
  }
}