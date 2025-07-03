# main.tf

# Tạo địa chỉ IP công cộng tĩnh cho MỖI VM
resource "google_compute_address" "vm_static_ip" {
  for_each     = var.vm_configs # Lặp qua từng cấu hình VM
  name         = "${each.value.name}"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  network_tier = var.network_tier # Giá trị này là chung cho tất cả các IP
}

# Tạo VM instance cho MỖI VM
resource "google_compute_instance" "default" {
  for_each     = var.vm_configs # Lặp qua từng cấu hình VM
  name         = each.value.name
  zone         = var.zone      # Giá trị zone là chung cho tất cả VM
  project      = var.project_id

  # Xác định machine_type: ưu tiên giá trị riêng của VM, nếu không thì dùng custom_vcpus/memory, nếu không thì dùng global machine_type
  machine_type = (each.value.machine_type != null ? each.value.machine_type :
                 "custom-${coalesce(each.value.custom_vcpus, var.custom_vcpus)}-${floor(coalesce(each.value.custom_memory_gb, var.custom_memory_gb) * 1024)}")
  
  # Giải thích coalesce ở trên:
  # coalesce(value_1, value_2, ...) trả về giá trị đầu tiên không null.
  # Nó kiểm tra if each.value.custom_vcpus có được định nghĩa không, nếu không thì dùng var.custom_vcpus.
  # Tương tự với custom_memory_gb.
  # Hoặc nếu bạn chỉ muốn dùng các loại máy custom:
  # machine_type = "custom-${coalesce(each.value.custom_vcpus, var.custom_vcpus)}-${floor(coalesce(each.value.custom_memory_gb, var.custom_memory_gb) * 1024)}"


  boot_disk {
    initialize_params {
      # Ưu tiên giá trị riêng của VM, nếu không thì dùng biến global
      image = coalesce(each.value.boot_disk_image, var.boot_disk_image)
      size  = coalesce(each.value.boot_disk_size, var.boot_disk_size)
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip       = google_compute_address.vm_static_ip[each.key].address # Gán IP tĩnh tương ứng
      network_tier = var.network_tier
    }
  }

#   metadata_startup_script = each.value.startup_script
#   allow_stopping_for_update = true

#   tags = coalesce(each.value.tags, ["ssh"]) # Ưu tiên tags riêng, nếu không thì mặc định là chỉ SSH

#   service_account {
#     email  = "default"
#     scopes = ["cloud-platform"]
#   }

  desired_status = var.vm_desired_status # Trạng thái mong muốn là chung cho tất cả VM
}