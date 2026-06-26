variable "keycloak_provider_url" {
  type = string
}

variable "keycloak_provider_client_secret" {
  type = string
}

variable "password_seeds" {
  description = "Map of DIZ name -> password seed. Each DIZ uses its own seed to derive its client secrets."
  type        = map(string)
}

variable "password_seed_version" {
  type    = number
  default = 3
}
