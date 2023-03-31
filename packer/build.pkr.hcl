build {
  sources = [
    "source.amazon-ebs.builder",
  ]

  provisioner "ansible" {
    groups = [ "${var.configuration_group}" ]
    playbook_file = "${var.playbook_file_path}"
    extra_arguments  = [
      "-e", "aws_region=${var.aws_region}",
      "-e", "aws_s3_release_bucket=${var.aws_s3_release_bucket}"
    ]
  }
}
