build {
  sources = [
    "source.amazon-ebs.webserver"
  ]
  provisioner "shell" {
    inline = [
      "sudo yum update -y",
      "sudo amazon-linux-extras install -y epel",
      "sudo yum install -y @development jq git",
      "sudo yum install httpd -y",
      "echo 'version 2' | sudo tee /var/www/html/index.html",
      "sudo systemctl enable httpd"
    ]
  }
  post-processor "amazon-ami-management" {
    regions = [var.region]
    identifier = local.prj_name
    keep_releases = 3
  }
}
