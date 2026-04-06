variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "k3s-lab"
}

variable "local_path" {
  type        = string
  description = "Local file path for mock provisioning"
  default     = "/tmp/k3s-lab-terraform"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default = {
    Project     = "k3s-lab"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}
