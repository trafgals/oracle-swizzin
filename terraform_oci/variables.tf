# Swizzin settings
# Set username and password for Swizzin console
variable "swizzin_username" {  type = string  }

variable "swizzin_password" {
  type = string
  sensitive = true
}

variable "cloudflare_domainname" {  type = string  }

variable "cloudflare_email" {  type = string  }

# Get token from https://dash.cloudflare.com/profile/api-tokens
variable "cloudflare_domain_api_token" {
  type = string
  default = null
  sensitive = true
}


# Oracle Variables
variable "compartment_ocid" {  type = string  }

variable "region" {
  default = "us-ashburn-1"
}

variable "availability_domain_number" {  default = 0  }

variable "availability_domain_name" {  default = ""  }

variable "ocpus_per_node" {
  type    = number
  default = 4  # Now limited to 4 on free tier
}

variable "memory_in_gbs_per_node" {
  type    = number
  default = 24
}


# OS Images
variable "instance_os" {
  description = "Operating system for compute instances"
  default     = "Canonical Ubuntu" # was "Oracle Linux"
}

variable "linux_os_version" {
  description = "Operating system version for all Linux instances"
  default     = "22.04" # Was "7.9"
}

variable "instance_shape" {
  default = "VM.Standard.A1.Flex" # was "VM.Standard.E4.Flex"
}

locals {
  availability_domain_name = var.availability_domain_name == "" ? lookup(data.oci_identity_availability_domains.ads.availability_domains[var.availability_domain_number], "name") : var.availability_domain_name
}
