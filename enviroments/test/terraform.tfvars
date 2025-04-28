# enviroments/test/terraform.tfvars

location            = "eastus"
resource_group_name = "rg-app-testing"
app_name            = "users-api"
image_tag           = "latest"
port                = 8083

env_vars = {
  JWT_SECRET  = "TEST_SECRET"
  SERVER_PORT = "8083"
}
