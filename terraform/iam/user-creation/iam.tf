terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.69.0"  # Adjust version as needed
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

#------------------------------------
# IAM User Creation
#------------------------------------
resource "aws_iam_user" "prabhu" {
  name = "prabhu"
  path = "/admin/"

  tags = {
    Name = "iam-prabhu"  # Updated tag key
  }
}

# Set the password manually
variable "prabhu_password" {
  description = "Password for the IAM user"
  default     = "password"  # Change this to your desired password
}

# IAM User Login Profile Creation
resource "aws_iam_user_login_profile" "prabhu" {
  user     = aws_iam_user.prabhu.name
  #password = var.prabhu_password  # Use the manual password
  # pgp_key  = "keybase:your_keybase_username"  # Optional: Use a PGP key for password encryption
}

# Create a null resource to create the login CSV
resource "null_resource" "console_login_csv" {
  triggers = {
    username = aws_iam_user.prabhu.name
    password = var.prabhu_password
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${path.module}/prabhu  # Create the directory if it doesn't exist
      echo "Username,Password" > ${path.module}/prabhu/console-login.csv
      echo "${self.triggers.username},${self.triggers.password}" >> ${path.module}/prabhu/console-login.csv
    EOT
  }
}

#------------------------------------
# IAM Group Creation
#------------------------------------
resource "aws_iam_group" "administrator" {
  name = "administrator"
  path = "/admin/"
}

# Attach user into group
resource "aws_iam_group_membership" "administrator" {
  name = "Add user into the administrator group"
  group = aws_iam_group.administrator.name
  users = [
    aws_iam_user.prabhu.name
  ]
}

# IAM Attach the policy to the administrator Group
resource "aws_iam_group_policy_attachment" "admin_policy_attachment" {
  group      = aws_iam_group.administrator.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Access Key Creation
resource "aws_iam_access_key" "prabhu" {
  user = aws_iam_user.prabhu.name
}

# Write Access Key to CSV File
resource "local_file" "access_key_csv" {
  filename = "${path.module}/prabhu/access-key.csv"  # Path to save the file
  content  = <<EOT
AccessKeyId,SecretAccessKey
${aws_iam_access_key.prabhu.id},${aws_iam_access_key.prabhu.secret}
EOT
}
