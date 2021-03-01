variable "env" {}

variable "www_domain_name" {}

variable "domain_name" {}

variable "certificate_arn" {}

variable "zone_id" {}

variable "aws_region" {}

variable "fetch_history_version" {
  
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "client_application" {
  env = var.env
  certificate_arn = var.certificate_arn
  zone_id = var.zone_id
  domain_name = var.domain_name
  www_domain_name = var.www_domain_name
  source  = "./modules/s3-cloudfront-website"
}

module "fetch-history-function" {
  env = var.env
  source = "./modules/lambda-s3-function"
  function_version = var.fetch_history_version
}