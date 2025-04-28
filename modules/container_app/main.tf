provider "azurerm" {
  features {}
  subscription_id = "36ae0aa4-14f2-4d0d-9f02-b3307f324b88"
}

resource "azurerm_log_analytics_workspace" "la" {
  name                = "${var.name_prefix}-logs"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}




# Crear el Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.name_prefix}acr${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Crear el Container App Environment
#resource "azurerm_container_app_environment" "env" {
#  name                = "${random_string.suffix.result}-env"
#  resource_group_name = var.resource_group_name
#  location            = var.location
#  log_analytics_workspace_id = azurerm_log_analytics_workspace.la.id
#}

#Declarar el container app
data "azurerm_container_app_environment" "env" {
  name                = "gyvpcp-env"
  resource_group_name = "rg-app-testing"
}





#Redis
resource "azurerm_container_app" "redis" {
  name                         = "${var.name_prefix}-redis"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "redis"
      image  = "redis:7"
      cpu    = 0.5
      memory = "1Gi"
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = false  
    target_port      = 6379
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}

resource "azurerm_container_app" "todos_api" {
  name                         = "${var.name_prefix}-todos-api-ca"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"


  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }



  template {
    container {
      name   = "todos-api"
      image  = "node:14-alpine"
            
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "TODO_API_PORT"
        value = "8082"
      }

      env {
        name  = "JWT_SECRET"
        value = "PRFT"
      }

      env {
        name  = "REDIS_HOST"
        value = azurerm_container_app.redis.name
      }

      env {
        name  = "REDIS_PORT"
        value = "6379" 
      }

      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 8082
    transport        = "auto"
    traffic_weight {
      percentage     = 100
      latest_revision = true
    }
  }
}






#Users API
resource "azurerm_container_app" "users_api" {
  name                         = "${var.name_prefix}-users-api-ca"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"


  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }


  template {
    container {
      name   = "users-api"
      image  = "openjdk:8-jdk-alpine"


      #image  = "${azurerm_container_registry.acr.login_server}/users-api:latest"

      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "JWT_SECRET"
        value = "PRFT" 
      }

      env {
        name  = "SERVER_PORT"
        value = "8083"
      }
    }
    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 8083 
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}






#Auth API
resource "azurerm_container_app" "auth_api" {
  name                         = "${var.name_prefix}-auth-api-ca"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }



  template {
    container {
      name   = "auth-api"
      image  = "golang:1.18-alpine"

      #image  = "${azurerm_container_registry.acr.login_server}/auth-api:latest"

      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "AUTH_API_PORT"
        value = "8000"
      }
      env {
        name  = "USERS_API_ADDRESS"
        value = "http://${azurerm_container_app.users_api.name}:8083"  
      }
      env {
        name  = "JWT_SECRET"
        value = "PRFT" 
      }
    }
    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true 
    target_port      = 8000
    transport        = "auto" 
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}


#Frontend
resource "azurerm_container_app" "frontend" {
  name                         = "${var.name_prefix}-frontend-ca"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  

  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }


  template {
    container {
      name   = "frontend"
      image  = "node:14-alpine"

      #image  = "${azurerm_container_registry.acr.login_server}/frontend:latest"
      
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "8080"
      }

      env {
        name  = "AUTH_API_ADDRESS"
        value = ""
      }
      
      env {
        name  = "TODOS_API_ADDRESS"
        value = ""
      }
    }
    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "auto"
    traffic_weight {
      percentage = 100
      latest_revision = true
    }
  }
}


resource "azurerm_container_app" "log_message_processor" {
  name                         = "${var.name_prefix}-log-message-processor-ca"
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  registry {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }

  template {
    container {
      name   = "log-message-processor"
      image  = "python:3.9-slim" 

      #image  = "${azurerm_container_registry.acr.login_server}/log-msg-process:latest"
      
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "REDIS_HOST"
        value = azurerm_container_app.redis.name 
      }

      env {
        name  = "REDIS_PORT"
        value = "6379"
      }

      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = false
    target_port      = 8080 
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}












# API Management (API Gateway)
#resource "azurerm_api_management" "api_management" {
#  name                = "api-${random_string.suffix.result}"
#  location            = var.location
#  resource_group_name = var.resource_group_name
#  publisher_name      = "Icesi University"
#  publisher_email     = "jaco2419@gmail.com"
#  sku_name           = "Consumption_0"  
#}

# Create API Management Gateway API
#resource "azurerm_api_management_api" "api_gateway" {
#  name                = "gateway-api"
#  resource_group_name = var.resource_group_name
#  api_management_name = azurerm_api_management.api_management.name
#  revision            = "1"
#  display_name        = "To-do's API Gateway"
#  path                = ""
#  protocols           = ["https"]
#}


#data "azurerm_api_management" "api_management" {
#  name = "api-testing-ca"
#  resource_group_name = "rg-app-testing"
#}

#data "azurerm_api_management_gateway" "api_gateway" {
#  name                = "default"
#  api_management_id  = data.azurerm_api_management.api_management.id
#}



# Create Users API in API Management
#resource "azurerm_api_management_api" "users_api" {
#  name                = "users-api"
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  revision            = "1"
#  display_name        = "Users-api"
#  protocols           = ["https"]
#  service_url         = "https://${azurerm_container_app.users_api.ingress[0].fqdn}"
#}

# Create Auth API in API Management
#resource "azurerm_api_management_api" "auth_api" {
#  name                = "auth-api"
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  revision            = "1"
#  display_name        = "Auth-api"
#  path                = "auth"
#  protocols           = ["https"]
#  service_url         = "https://${azurerm_container_app.auth_api.ingress[0].fqdn}"
#}

# Create Todos API in API Management
#resource "azurerm_api_management_api" "todos_api" {
#  name                = "to-do-api"
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  revision            = "1"
#  display_name        = "To-Do-api"
#  path                = "todo"
#  protocols           = ["https"]
#  service_url         = "https://${azurerm_container_app.todos_api.ingress[0].fqdn}"
#}

# Users API operations
#resource "azurerm_api_management_api_operation" "get_users" {
#  operation_id        = "get-users"
#  api_name            = azurerm_api_management_api.users_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Get users"
#  method              = "GET"
#  url_template        = "/users/"
#}

#resource "azurerm_api_management_api_operation" "get_user" {
#  operation_id        = "get-user"
#  api_name            = azurerm_api_management_api.users_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Get User"
#  method              = "GET"
#  url_template        = "/users/{id}"
  
#  template_parameter {
#    name        = "id"
#    required    = true
#    type        = "string"
#  }
#}

# Auth API operations
#resource "azurerm_api_management_api_operation" "login" {
#  operation_id        = "login"
#  api_name            = azurerm_api_management_api.auth_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Login"
#  method              = "POST"
#  url_template        = "/login"
#}

# Todos API operations
#resource "azurerm_api_management_api_operation" "get_to_do_s" {
#  operation_id        = "get-to-do-s"
#  api_name            = azurerm_api_management_api.todos_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Get To-Do's"
#  method              = "GET"
#  url_template        = "/todos"
#}

#resource "azurerm_api_management_api_operation" "create_to_do_s" {
#  operation_id        = "create-to-do-s"
#  api_name            = azurerm_api_management_api.todos_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Create To-Do's"
#  method              = "POST"
#  url_template        = "/todos"
#}

#resource "azurerm_api_management_api_operation" "delete_to_do_s" {
#  operation_id        = "delete-to-do-s"
#  api_name            = azurerm_api_management_api.todos_api.name
#  resource_group_name = "rg-app-testing"
#  api_management_name = data.azurerm_api_management.api_management.name
#  display_name        = "Delete To-Do's"
#  method              = "DELETE"
#  url_template        = "/todos/{id}"
  
#  template_parameter {
#    name        = "id"
#    required    = true
#    type        = "string"
#  }
#}







