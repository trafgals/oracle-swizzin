# Get list of availability domains

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  compartment_id           = var.compartment_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version
  shape                    = var.instance_shape
}

data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.compartment_ocid

  filter {
    name   = "is_home_region"
    values = [true]
  }
}

