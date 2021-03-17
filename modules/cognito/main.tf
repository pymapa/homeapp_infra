variable "env" {}

resource "aws_cognito_user_pool" "pool" {
  name = "homeapp-${var.env}"

  alias_attributes = ["email", "preferred_username"]

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "nickname"
    required            = true
  }

  password_policy {
    minimum_length    = "8"
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  mfa_configuration        = "OFF"
  auto_verified_attributes = ["email"]

  tags = {
    "Name" = "HomeAppCognito-${var.env}"
  }

  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  user_pool_id = aws_cognito_user_pool.pool.id
  domain       = "pyry-home-app-${var.env}"
}

resource "aws_cognito_user_pool_client" "client" {
  user_pool_id = aws_cognito_user_pool.pool.id

  name                   = "homeapp-client-${var.env}"
  refresh_token_validity = 30
  read_attributes        = ["nickname"]
  write_attributes       = ["nickname"]

  supported_identity_providers = ["COGNITO"]
  callback_urls                = ["http://localhost:3000"]
  logout_urls                  = ["http://localhost:3000"]
}

resource "aws_cognito_identity_pool" "identity" {
  identity_pool_name               = "homeapp-${var.env}"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = false
  }
}

resource "aws_cognito_identity_pool_roles_attachment" "id_roles" {
  identity_pool_id = aws_cognito_identity_pool.test_app_id_pool.id

  roles = {
    "authenticated"   = aws_iam_role.api_gateway_access.arn
    "unauthenticated" = aws_iam_role.deny_everything.arn
  }
}

resource "aws_iam_role_policy" "api_gateway_access" {
  name   = "api-gateway-access"
  role   = aws_iam_role.api_gateway_access.id
  policy = data.aws_iam_policy_document.api_gateway_access.json
}

resource "aws_iam_role" "api_gateway_access" {
  name = "ap-gateway-access"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.identity.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "authenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "api_gateway_access" {
  version = "2012-10-17"
  statement {
    actions = [
      "execute-api:Invoke"
    ]

    effect = "Allow"

    resources = ["arn:aws:execute-api:*:*:*"]
  }
}

resource "aws_iam_role_policy" "deny_everything" {
  name   = "deny_everything"
  role   = aws_iam_role.deny_everything.id
  policy = data.aws_iam_policy_document.deny_everything.json
}

resource "aws_iam_role" "deny_everything" {
  name = "deny_everything"
  # This will grant the role the ability for cognito identity to assume it
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "cognito-identity.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "cognito-identity.amazonaws.com:aud": "${aws_cognito_identity_pool.test_app_id_pool.id}"
        },
        "ForAnyValue:StringLike": {
          "cognito-identity.amazonaws.com:amr": "unauthenticated"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "deny_everything" {
  version = "2012-10-17"

  statement {
    actions = ["*"]
    effect    = "Deny"
    resources = ["*"]
  }
}
