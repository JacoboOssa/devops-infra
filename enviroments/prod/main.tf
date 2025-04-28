terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatexpichi"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

module "app_prod" {
  source              = "../../modules/container_app"
  name_prefix         = "prod"
  location            = var.location
  resource_group_name = var.resource_group_name
  app_name            = var.app_name
  image_tag           = var.image_tag
  port                = var.port
  env_vars            = var.env_vars
}
