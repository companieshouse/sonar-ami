local "aws_source_ami_owner_id" {
    expression = vault("/aws-accounts/account-ids", "development")
    sensitive   = true
}