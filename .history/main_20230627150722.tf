# Define the provider (GCP)
provider "google" {
  project = "doassign"
  region  = "us-central1"
  zone    = "us-central1-c"
}

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  name                    = "my-vpc-network"
  auto_create_subnetworks = false
}

#public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc_network.self_link
  region        = "us-central1"
}

#private
resource "google_compute_subnetwork" "private-subnet" {
  name                       = "private-subnet"
  ip_cidr_range              = "10.0.2.0/24"
  network                    = google_compute_network.vpc_network.self_link
  region                     = "us-central1"
  private_ip_google_access   = true
  private_ipv6_google_access = true
}

resource "google_compute_instance" "public_instance" {
  name         = "public-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.public_subnet.id
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    sudo ufw allow 'Nginx HTTP'
    systemctl enable nginx
    systemctl start nginx
  EOF
}

resource "google_compute_instance" "private_instance" {
  name         = "private-instance"
  machine_type = "e2-micro"
  zone         = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.private-subnet.id
  }

  # Disable external IP forwarding for the private instance
  network_interface {
    access_config {
      nat_ip = ""
    }
  }

  # metadata_startup_script = <<-EOF
  #   #!/bin/bash
  #   # Add necessary configuration for private instance
  # EOF
}

