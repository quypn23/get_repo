# variables.tf

# ... (Giữ nguyên các biến gcp_project_id, gcp_region, gcp_zone nếu bạn muốn chúng áp dụng chung cho tất cả VM)

variable "vm_instances" {
  description = "A map of VM instance configurations."
  type = map(object({
    name              = string
    machine_type      = string
    boot_disk_image   = string
    boot_disk_size_gb = number
    startup_script    = optional(string, "") # Đặt optional nếu không phải VM nào cũng có script
    tags              = optional(list(string), ["ssh"]) # Thẻ mặc định là ssh
  }))
  default = {
    # Định nghĩa cấu hình cho VM thứ nhất
    "web-server-01" = {
      name              = "web-server-01"
      machine_type      = "e2-medium"
      boot_disk_image   = "ubuntu-os-cloud/ubuntu-2004-lts"
      boot_disk_size_gb = 30
      startup_script    = <<-EOT
                          #!/bin/bash
                          sudo apt-get update
                          sudo apt-get install -y nginx
                          echo "Hello from Web Server 01!" | sudo tee /var/www/html/index.html
                          EOT
      tags              = ["http-server", "ssh"]
    },
    # Định nghĩa cấu hình cho VM thứ hai
    "db-server-01" = {
      name              = "db-server-01"
      machine_type      = "e2-small"
      boot_disk_image   = "debian-cloud/debian-11"
      boot_disk_size_gb = 20
      startup_script    = <<-EOT
                          #!/bin/bash
                          echo "Installing PostgreSQL..."
                          # Add PostgreSQL installation commands here
                          EOT
      tags              = ["ssh", "db-server"] # Thêm tag riêng cho DB server nếu cần
    },
    # Bạn có thể thêm nhiều VM khác ở đây
  }
}