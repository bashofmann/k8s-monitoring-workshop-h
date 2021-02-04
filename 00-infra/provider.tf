terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.22.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "tls" {
}