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

#--------------------------------------------------------------------------------------
#MFA Policy for all users
resource "aws_iam_policy" "mfa_enforce_policy" {
  name        = "EnforceMFA"
  description = "Deny non-MFA console access for all users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DenyAllExceptForIAMUsersWithMFA"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

#--------------------------------------------------------------------------------------
# Developers Policies (need EC2 managing, and S3 read/write, also cloudwatch read only)

# Developers IAM Group
resource "aws_iam_group" "developers" {
    name = "Developers"
}

# Developer Policy block
resource "aws_iam_policy" "developer_policy" {
  name = "DeveloperAccessPolicy" #Name in console
  description = "Allow EC2 and S3 access, and read only Cloudwatch access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "ec2:*"
            ]
            Resource = "*" #means all
        },
        {
            Effect = "Allow"
            Action = [
                "s3:*"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = [
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*"
            ]
            Resource = "*"
        }
    ]
  })
}

# Attach dev policy to dev group
resource "aws_iam_group_policy_attachment" "developers_attachment" {
    group = aws_iam_group.developers.name # links to the developers group
    policy_arn = aws_iam_policy.developer_policy.arn #grabs the ARN of your custom policy and applies it to the group
}

# Create 4 users and assign to dev group
resource "aws_iam_user" "dev_user_1" {
  name = "dev-user-1"
}

resource "aws_iam_user_group_membership" "dev_user_1_membership" {
  user = aws_iam_user.dev_user_1.name
  groups = [
    aws_iam_group.developers.name #adds this user to developers iam group
  ]
}

resource "aws_iam_user" "dev_user_2" {
  name = "dev-user-2"
}

resource "aws_iam_user_group_membership" "dev_user_2_membership" {
  user = aws_iam_user.dev_user_2.name
  groups = [
    aws_iam_group.developers.name 
  ]
}

resource "aws_iam_user" "dev_user_3" {
  name = "dev-user-3"
}

resource "aws_iam_user_group_membership" "dev_user_3_membership" {
  user = aws_iam_user.dev_user_3.name
  groups = [
    aws_iam_group.developers.name 
  ]
}

resource "aws_iam_user" "dev_user_4" {
  name = "dev-user-4"
}

resource "aws_iam_user_group_membership" "dev_user_4_membership" {
  user = aws_iam_user.dev_user_4.name
  groups = [
    aws_iam_group.developers.name 
  ]
}

#------------------------------------------------------------------------------------------------
#Operations (Infrastructure access: ec2, cloudwatch, rds, system manager) (admin level access w/o billing and iam)

#Operations group
resource "aws_iam_group" "operations" {
  name = "Operations"
}

#Operations policy
resource "aws_iam_policy" "operations_policy" {
  name        = "OperationsAccessPolicy"
  description = "Full access to EC2, CloudWatch, RDS, and Systems Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "cloudwatch:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "rds:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ssm:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "operations_attachment" {
  group = aws_iam_group.operations.name
  policy_arn = aws_iam_policy.operations_policy.arn
}

# 2 operations users and add them to operations group
resource "aws_iam_user" "op_user_1" {
  name = "op-user-1"
}

resource "aws_iam_user_group_membership" "op_user_1_membership" {
  user = aws_iam_user.op_user_1.name
  groups = [
    aws_iam_group.operations.name
  ]
}

resource "aws_iam_user" "op_user_2" {
  name = "op-user-2"
}

resource "aws_iam_user_group_membership" "op_user_2_membership" {
  user = aws_iam_user.op_user_2.name
  groups = [
    aws_iam_group.operations.name
  ]
}

#------------------------------------------------------------------------------------------
#Finance Manager Policy group and user

resource "aws_iam_group" "finance" {
  name = "Finance"
}

#Policy gives Permission to cost management
resource "aws_iam_policy" "finance_policy" {
  name        = "FinanceAccessPolicy"
  description = "Access to billing (Cost Explorer, Budgets) and read-only permissions for all resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:*",           # Cost Explorer
          "budgets:*"       # Budgets
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [ #read only access
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "rds:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*",
          "iam:List*",
          "iam:Get*"
        ]
        Resource = "*"
      }
    ]
  })
}

#attach policy to group
resource "aws_iam_group_policy_attachment" "finance_attachment" {
  group      = aws_iam_group.finance.name
  policy_arn = aws_iam_policy.finance_policy.arn
}

#user and adding to group
resource "aws_iam_user" "finance_user" {
  name = "finance-manager"
}

resource "aws_iam_user_group_membership" "finance_user_membership" {
  user = aws_iam_user.finance_user.name
  groups = [
    aws_iam_group.finance.name
  ]
}

#--------------------------------------------------------------------------------
#Data analyst policy, group, and 3 users

resource "aws_iam_group" "analysts" {
  name = "Analysts"
}


#Policy for read only data access (s3 and rds)
resource "aws_iam_policy" "analyst_policy" {
  name        = "AnalystAccessPolicy"
  description = "Read-only access to S3 and RDS data resources"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

#attach policy to group
resource "aws_iam_group_policy_attachment" "analyst_attachment" {
  group      = aws_iam_group.analysts.name
  policy_arn = aws_iam_policy.analyst_policy.arn
}

#users and add to group
resource "aws_iam_user" "analyst_user_1" {
  name = "analyst-user-1"
}

resource "aws_iam_user_group_membership" "analyst_user_1_membership" {
  user = aws_iam_user.analyst_user_1.name
  groups = [
    aws_iam_group.analysts.name
  ]
}

resource "aws_iam_user" "analyst_user_2" {
  name = "analyst-user-2"
}

resource "aws_iam_user_group_membership" "analyst_user_2_membership" {
  user = aws_iam_user.analyst_user_2.name
  groups = [
    aws_iam_group.analysts.name
  ]
}

resource "aws_iam_user" "analyst_user_3" {
  name = "analyst-user-3"
}

resource "aws_iam_user_group_membership" "analyst_user_3_membership" {
  user = aws_iam_user.analyst_user_3.name
  groups = [
    aws_iam_group.analysts.name
  ]
}

#---------------------------------------------------------------------------------
# Attach MFA policy to all groups
resource "aws_iam_group_policy_attachment" "mfa_enforce_developers" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.mfa_enforce_policy.arn
}

resource "aws_iam_group_policy_attachment" "mfa_enforce_operations" {
  group      = aws_iam_group.operations.name
  policy_arn = aws_iam_policy.mfa_enforce_policy.arn
}

resource "aws_iam_group_policy_attachment" "mfa_enforce_finance" {
  group      = aws_iam_group.finance.name
  policy_arn = aws_iam_policy.mfa_enforce_policy.arn
}

resource "aws_iam_group_policy_attachment" "mfa_enforce_analysts" {
  group      = aws_iam_group.analysts.name
  policy_arn = aws_iam_policy.mfa_enforce_policy.arn
}