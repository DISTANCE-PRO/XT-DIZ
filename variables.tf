variable "keycloak_provider_url" {
  type = string
}

variable "keycloak_provider_client_secret" {
  type = string
}

variable "password_seed" {
  type = string
}

variable "password_seed_version" {
  type    = number
  default = 2
}
