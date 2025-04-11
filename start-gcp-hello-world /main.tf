# Create VPC network
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

# Create public subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
}

# New: Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "private-subnet"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  private_ip_google_access = true  # Allows private instances to reach Google APIs
}


# New: Cloud Router and NAT Gateway (for private subnet internet access)
resource "google_compute_router" "router" {
  name    = "nat-router"
  region  = var.region
  network = google_compute_network.vpc.id
}


resource "google_compute_router_nat" "nat" {
  name                               = "nat-gateway"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.private_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}


# Firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allow_ssh_from
  target_tags   = ["ssh"]
}

resource "google_compute_firewall" "allow_ssh_from_public" {
  name    = "allow-ssh-from-public-subnet"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.public_subnet_cidr]  # Public subnet CIDR
  target_tags   = ["ssh"]                   # Must match private VM's tags
}

# Create a VM in the public subnet
resource "google_compute_instance" "public_vm" {
  name         = "public-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["ssh","nodejs-server"] # Applies the firewall rule

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {
      # Assigns a public IP
    }
  }

metadata_startup_script = <<-EOF
  #!/bin/bash
  # Install Node.js
  sudo apt-get update
  curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sudo npm install -g pm2

  # Create app directory
  mkdir -p /opt/node-app
  cd /opt/node-app

  # Create the Node.js application
  cat > app.js << 'EOL'
  const express = require("express");
  const app = express();
  const PORT = 8080;

  app.get("/", (req, res) => {
    const name = req.query.name || "World";
    res.send("Hello, " + name + "!");
  });

  app.listen(PORT, '0.0.0.0',() => {
    console.log("Server running on port " + PORT);
  });
  EOL

  # Initialize npm and install dependencies
  npm init -y
  npm install express

  # Start the application with PM2
  pm2 start app.js
  pm2 startup
  pm2 save
EOF
  
}

resource "google_compute_firewall" "allow_nodejs_port" {
  name        = "allow-nodejs-port"
  network     = "default"
  description = "Allow incoming traffic on TCP port 8080 for Node.js apps"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["nodejs-server"] # Applies only to VMs with this tag
}

# Example VM in private subnet (no public IP)
resource "google_compute_instance" "private_vm" {
  name         = "private-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["ssh"] # Applies the firewall rule

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    # No access_config block = no public IP
  }
}