output "c8" {
  value = {
    public_ip    = aws_instance.c8.public_ip
    private_ip   = aws_instance.c8.private_ip
    hostname     = "c8.local"
    ansible_user = "ec2-user"
  }
}

output "u21" {
  value = {
    public_ip    = aws_instance.u21.public_ip
    private_ip   = aws_instance.u21.private_ip
    hostname     = "u21.local"
    ansible_user = "ubuntu"
  }
}

output "inventory_file" {
  value = "${path.module}/../ansible/inventory.ini"
}
