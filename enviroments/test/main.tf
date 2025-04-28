# enviroments/test/main.tf

module "app_test" {
  source              = "../../modules/container_app"
  name_prefix         = "test"
  location            = var.location
  resource_group_name = var.resource_group_name
  app_name            = var.app_name
  image_tag           = var.image_tag
  port                = var.port
  env_vars            = var.env_vars
}
