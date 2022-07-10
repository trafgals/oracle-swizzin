# Create VCN
resource "oci_core_virtual_network" "vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = var.compartment_ocid
  display_name   = "web-app-vcn"
  dns_label      = "tfexamplevcn"
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# Create regional subnets in vcn
resource "oci_core_subnet" "subnet_1" {
  cidr_block      = "10.0.0.0/24"
  display_name    = "subnet-A"
  compartment_id  = var.compartment_ocid
  vcn_id          = oci_core_virtual_network.vcn.id
  dhcp_options_id = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id  = oci_core_route_table.rt-pub.id
  dns_label       = "subnet1"
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

resource "oci_core_subnet" "subnet_2" {
  cidr_block      = "10.0.1.0/24"
  display_name    = "subnet-B"
  compartment_id  = var.compartment_ocid
  vcn_id          = oci_core_virtual_network.vcn.id
  dhcp_options_id = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id  = oci_core_route_table.rt-pub.id
  dns_label       = "subnet2"
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

resource "oci_core_subnet" "subnet_3" {
  cidr_block                 = "10.0.2.0/24"
  display_name               = "subnet-C"
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_virtual_network.vcn.id
  dhcp_options_id            = oci_core_virtual_network.vcn.default_dhcp_options_id
  route_table_id             = oci_core_route_table.rt-priv.id
  dns_label                  = "subnet3"
  prohibit_public_ip_on_vnic = true
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# Create internet gateway to allow public internet traffic
resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_ocid
  display_name   = "ig-gateway"
  vcn_id         = oci_core_virtual_network.vcn.id
}

resource "oci_core_nat_gateway" "nat_gw" {
  compartment_id = var.compartment_ocid
  display_name   = "nat_gateway"
  vcn_id         = oci_core_virtual_network.vcn.id
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}


# Create route table to connect vcn to internet gateway
resource "oci_core_route_table" "rt-pub" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "rt-table-pub"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.ig.id
  }
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

resource "oci_core_route_table" "rt-priv" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_virtual_network.vcn.id
  display_name   = "rt-table-priv"
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gw.id
  }
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}


# VMSecurityGroup - allow incoming connections on ports 22 and 80
resource "oci_core_network_security_group" "VMSecurityGroup" {
  compartment_id = var.compartment_ocid
  display_name   = "VMSecurityGroup"
  vcn_id         = oci_core_virtual_network.vcn.id
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }
}

# Rules related to SSHSecurityGroup
# EGRESS
resource "oci_core_network_security_group_security_rule" "SSHSecurityEgressGroupRule" {
  network_security_group_id = oci_core_network_security_group.VMSecurityGroup.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}
# INGRESS
resource "oci_core_network_security_group_security_rule" "SSHSecurityIngressGroupRules" {
  network_security_group_id = oci_core_network_security_group.VMSecurityGroup.id
  direction                 = "INGRESS"
  protocol                  = "all"
  source                    = "0.0.0.0/0"
  source_type               = "CIDR_BLOCK"
}
