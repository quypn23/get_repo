# variables.tf (Thêm biến này hoặc thay đổi biến instance_name hiện tại)

# Giữ nguyên các biến bạn đã định nghĩa ở trên (project_id, region, zone, ...)
# ...

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
    tags              = optional(list(string), ["ssh"]) # Các tag riêng
  }))
  default = {
    "web-server-01" = {
      name              = "web-server-01"
      # Các thuộc tính khác sẽ lấy từ các biến mặc định global (ví dụ: e2-standard-2, ubuntu-2204, 40GB disk)
      startup_script    = <<-EOT
                          #!/bin/bash
                          sudo apt-get update && sudo apt-get install -y nginx
                          echo "<h1>Hello from Web Server 01!</h1>" | sudo tee /var/www/html/index.html
                          EOT
      tags              = ["http-server", "ssh"]
    },
    "db-server-01" = {
      name              = "db-server-01"
      machine_type      = "e2-medium" # Ghi đè loại máy
      boot_disk_image   = "debian-cloud/debian-11" # Ghi đè image
      boot_disk_size    = 20 # Ghi đè kích thước disk
      startup_script    = <<-EOT
                          #!/bin/bash
                          echo "This is DB Server 01 setup."
                          # Add PostgreSQL or MySQL installation here
                          EOT
      tags              = ["ssh", "db-access"] # Ghi đè tags
    },
    "jenkins-agent-01" = {
      name              = "jenkins-agent-01"
      custom_vcpus      = 2
      custom_memory_gb  = 8
      boot_disk_size    = 80
      startup_script    = <<-EOT
                          #!/bin/bash
                          echo "Configuring Jenkins agent..."
                          # Commands to setup Jenkins agent
                          EOT
      tags              = ["ssh", "jenkins-agent"]
    }
  }
}