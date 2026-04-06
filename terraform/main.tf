terraform {
  required_version = ">= 1.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }

  # TODO: Configure remote backend (e.g., S3, Terraform Cloud)
  # backend "s3" {
  #   bucket = "k3s-lab-tfstate"
  #   key    = "dev/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "local" {}

# Mock local file resource to demonstrate IaC structure
# In a real cloud deployment, this would provision actual infrastructure
resource "local_file" "k3s_lab_config" {
  filename = "${var.local_path}/config.txt"
  content = templatefile("${path.module}/templates/config.tpl", {
    project     = var.project_name
    environment = var.environment
    timestamp   = timestamp()
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Output for verification
output "k3s_lab_config_path" {
  description = "Path to the k3s lab configuration file"
  value       = local_file.k3s_lab_config.filename
}

output "project_tags" {
  description = "Common tags applied to resources"
  value       = var.tags
}
