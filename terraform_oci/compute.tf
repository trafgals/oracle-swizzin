# To delete and recreate the instance, comment out this file, run terraform, and then uncomment it, then run terraform again

data "cloudflare_zone" "main" {
    name = var.cloudflare_domainname
}

# Create a record that points the domain at the Swizzin IP address
resource "cloudflare_record" "swizzin_root" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  value   = oci_core_instance.compute_instance1.public_ip
  type    = "A"
  ttl     = 60
  allow_overwrite = true
}

resource "cloudflare_record" "swizzin_www" {
  zone_id = data.cloudflare_zone.main.id
  name    = "www"
  value   = oci_core_instance.compute_instance1.public_ip
  type    = "A"
  ttl     = 60
  allow_overwrite = true
}


# Create Compute Instance
resource "oci_core_instance" "compute_instance1" {
  availability_domain = local.availability_domain_name
  compartment_id      = var.compartment_ocid
  display_name        = "swizzin-host"
  shape               = var.instance_shape
  fault_domain = "FAULT-DOMAIN-1"

  # Below is necessary to tell Terraform to ignore the automatic tags that Oracle sets (and not inadvertently receate the instance)
  lifecycle {
    ignore_changes = [defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"]]
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.InstanceImageOCID.images[0].id
    boot_volume_size_in_gbs = "200"
  }

  shape_config {
    memory_in_gbs = var.memory_in_gbs_per_node
    ocpus         = var.ocpus_per_node
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.subnet_2.id
    nsg_ids   = [oci_core_network_security_group.VMSecurityGroup.id]
  }

  metadata = {
    ssh_authorized_keys = "${trimspace(tls_private_key.public_private_key_pair.public_key_openssh)} key-generated-by-terraform"
  }

  timeouts {
    create = "60m"
  }
}


resource random_password "ignore_this" {
  # Sets up a random string password for swizzin at installtime that never gets used
  length = 20
  special = false
}

resource "null_resource" "set_up_vm_for_swizzin" {
  # We need to stick the provisioner inside this "null_resource" to make sure it runs every time the VM changes
  triggers = {
    always_run = "${timestamp()}"  # Run every time we apply terraform
  }

  provisioner "local-exec" {
    # Download the latest version of swizzin
    command = "curl -o install_swizzin.sh -sL git.io/swizzin"
  }

  # Copy over swizzin install script
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = oci_core_instance.compute_instance1.public_ip
      private_key = trimspace(tls_private_key.public_private_key_pair.private_key_pem)
      agent       = false
      timeout     = "1m"
    }
    source = "./install_swizzin.sh"
    destination = "/home/ubuntu/install_swizzin.sh"
  }

  # Write an env file to the VM for swizzin to apply
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = oci_core_instance.compute_instance1.public_ip
      private_key = trimspace(tls_private_key.public_private_key_pair.private_key_pem)
      agent       = false
      timeout     = "1m"
    }
    # Below holds ENV file for Swizzin, see details at https://swizzin.ltd/guides/advanced-setup#env-file
    # Complains about inline comments so remove these
    content = <<-EOT
pass=${random_password.ignore_this.result}
test=true
EOT
    destination = "/home/ubuntu/swizzin_dotenv"
  }

  # Install swizzin with defaults
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = oci_core_instance.compute_instance1.public_ip
      private_key = trimspace(tls_private_key.public_private_key_pair.private_key_pem)
      agent       = false
      timeout     = "60m"
    }
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",  # Tell the server to not ask for prompts
      "chmod +x /home/ubuntu/install_swizzin.sh",  # Make the installer executable
      "sudo ufw disable",  # Allow the server to listen on HTTP and HTTPS
      "sudo -i bash -c \"ufw disable && systemctl stop ufw && systemctl disable ufw\"",  # Remove the ufw service
      # Below disables all the iptables firewall rules that are set up by oracle cloud by default
      "sudo -i bash -c \"iptables -P INPUT ACCEPT && iptables -P OUTPUT ACCEPT && iptables -P FORWARD ACCEPT && iptables -F\"",
      # Below uninstalls iptables and iptables-persistent
      "sudo -i bash -c \"apt-get remove -y ufw iptables iptables-persistent && apt-get autoremove -y\"",
      # Install swizzin if 'box test nginx' fails (otherwise we already have swizzin installed). Install Plex to set up the plex group
      "sudo -i bash -c \"box test nginx || /home/ubuntu/install_swizzin.sh --env /home/ubuntu/swizzin_dotenv --user ${var.swizzin_username} --domain ${var.cloudflare_domainname} nginx panel letsencrypt plex\"",
      "sudo -i bash -c 'usermod -a -G ${var.swizzin_username} plex'",  # Add user to Plex group
      "sudo -i bash -c 'chmod -R 0777 /home/${var.swizzin_username}'",  # Give user's homedir write permissions to Plex group
      "sudo -i bash -c 'mkdir 0777 /home/${var.swizzin_username}/downloads'",  # Create somewhere to stick all the downloads
      "sudo -i bash -c 'mkdir 0777 /home/${var.swizzin_username}/Movies'", # Below aligns to NZBGet categories
      "sudo -i bash -c 'mkdir 0777 /home/${var.swizzin_username}/TV'",
      "sudo -i bash -c 'mkdir 0777 /home/${var.swizzin_username}/Music'",
      "sudo -i bash -c 'mkdir 0777 /home/${var.swizzin_username}/Software'",
      "sudo -i bash -c 'chown -R ${var.swizzin_username}:plex /home/${var.swizzin_username}'",
      # Clean up install scripts
      "rm -f /home/ubuntu/install_swizzin.sh && rm -f /home/ubuntu/swizzin_dotenv",
    ]
  }

  # break it up so we get diagnostics on the above provisioner
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      host        = oci_core_instance.compute_instance1.public_ip
      private_key = trimspace(tls_private_key.public_private_key_pair.private_key_pem)
      agent       = false
      timeout     = "60m"
    }
    inline = [
      # Write username and encrypted password to panel access file
      "sudo -i bash -c 'box chpasswd ${var.swizzin_username} ${var.swizzin_password}'",
      # Restart the server
      "sudo -i bash -c 'shutdown --reboot +1'",
    ]
  }
}