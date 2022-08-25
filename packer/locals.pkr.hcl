locals  {
    aws_source_ami_owner_id = vault("/aws-accounts/account-ids", "development")
}