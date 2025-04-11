output "vpc_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "public_subnet_name" {
  description = "Name of the public subnet"
  value       = google_compute_subnetwork.public_subnet.name
}

output "vm_public_ip" {
  description = "Public IP of the VM"
  value       = google_compute_instance.public_vm.network_interface[0].access_config[0].nat_ip
}

# New outputs
output "private_subnet_name" {
  value = google_compute_subnetwork.private_subnet.name
}

output "private_vm_internal_ip" {
  value = google_compute_instance.private_vm.network_interface[0].network_ip
}