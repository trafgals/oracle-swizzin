terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
      version = "~> 4"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3"
    }
  }
}

provider "oci" {
  region       = var.region
  #  user_ocid            = var.user_ocid
  #  fingerprint          = var.fingerprint
  #  private_key          = var.private_key_path
  disable_auto_retries = "true"
}

provider "oci" {
  alias        = "homeregion"
  region       = data.oci_identity_region_subscriptions.home_region_subscriptions.region_subscriptions[0].region_name
  #  user_ocid            = var.user_ocid
  #  fingerprint          = var.fingerprint
  #  private_key          = var.private_key_path
  disable_auto_retries = "true"
}

provider "cloudflare" {
  email     = var.cloudflare_email
  api_token = var.cloudflare_domain_api_token
}
