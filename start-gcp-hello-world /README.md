# GCP VPC with Public Subnet - Terraform

## Overview
Deploys a Google Cloud VPC with:
- A public subnet
- Firewall rule allowing SSH
- A compute instance with a public IP

## Usage
1. Set up authentication:
   ```sh
   gcloud auth application-default login