terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  # Optional: Store Terraform state in Google Cloud Storage (GCS)
 backend "local" {
   path = "terraform.tfstate"
  }
}

provider "google" {
  credentials = file("terraform-key.json") # Path to your service account key
  project     = "astute-sign-456208-q9"
  region      = "us-central1"
}