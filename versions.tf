terraform {
  required_version = ">= 1.6"

  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = "5.7.0"
    }
  }
}

provider "keycloak" {
  url           = var.keycloak_provider_url
  client_id     = "terraform"
  client_secret = var.keycloak_provider_client_secret
}
