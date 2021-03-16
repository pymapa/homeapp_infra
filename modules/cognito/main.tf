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
  user_pool_id = "${aws_cognito_user_pool.pool.id}"
  domain = "pyry-home-app-${var.env}"
}

resource "aws_cognito_user_pool_client" "client" {
  user_pool_id = "${aws_cognito_user_pool.pool.id}"

  name                   = "homeapp-client-${var.env}"
  refresh_token_validity = 30
  read_attributes  = ["nickname"]
  write_attributes = ["nickname"]

  supported_identity_providers = ["COGNITO"]
  callback_urls                = ["http://localhost:3000"]
  logout_urls                  = ["http://localhost:3000"]
}