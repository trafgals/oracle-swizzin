resource "tls_private_key" "public_private_key_pair" {
  algorithm = "RSA"
}

resource "local_file" "pem_private_key" {
  content         = trimspace(tls_private_key.public_private_key_pair.private_key_pem)
  filename        = "id_rsa"
  file_permission = "0600"
}

resource "local_file" "openssh_private_key" {
  content         = trimspace(tls_private_key.public_private_key_pair.private_key_openssh)
  filename        = "id_rsa.ppk"
  file_permission = "0600"
}
resource "local_file" "ssh_public_key" {
  content         = trimspace(tls_private_key.public_private_key_pair.public_key_openssh)
  filename        = "id_rsa.pub"
  file_permission = "0600"
}
