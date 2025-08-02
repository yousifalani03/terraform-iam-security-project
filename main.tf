#Core Terraform Config: resources(users, groups, policies, etc)

# 1: Set a password policy for all IAM users (this is global for aws account)

resource "aws_iam_account_password_policy" "strict_policy" {
    minimum_password_length = 12  #this length is secure for passwords
    require_lowercase_characters = true
    require_uppercase_characters = true
    require_numbers = true
    require_symbols = true

    max_password_age = 90 #reset password every 90 days
    password_reuse_prevention = 5 #cant use last 5 passwords

    allow_users_to_change_password = true
    hard_expiry = false #not locked out if pw expires
}