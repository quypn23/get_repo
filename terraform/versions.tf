terraform {
  required_version = ">= 1.0.0" #version  terraform tối thiểu

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.0"
  }
  }
}

#
provider "google" {
    project = var.project_id
    region = var.region
    zone = var.zone
}
