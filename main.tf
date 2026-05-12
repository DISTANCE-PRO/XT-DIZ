data "keycloak_realm" "distance_xt" {
  realm = "distance-xt"
}

locals {
  dizs = toset(yamldecode(file(".gitlab-ci.yml"))[".dizs"])
}

# Realm role in the core realm, assigned to admin users centrally.
# Mapped into each per-DIZ realm via the identity provider role mapper
# (see auth-realm/broker.tf).
resource "keycloak_role" "core_cd_admin" {
  realm_id = data.keycloak_realm.distance_xt.id
  name     = "cd-admin"
}

# Realm roles in the core realm, expected by the trust-center-agent.
resource "keycloak_role" "core_cd" {
  realm_id = data.keycloak_realm.distance_xt.id
  name     = "cd-agent"
}

resource "keycloak_role" "core_rd" {
  realm_id = data.keycloak_realm.distance_xt.id
  name     = "rd-agent"
}

module "auth_realm" {
  for_each              = local.dizs
  source                = "./auth-realm"
  name                  = each.key
  core_realm_id         = data.keycloak_realm.distance_xt.id
  keycloak_base_url     = var.keycloak_provider_url
  core_cd_role_name     = keycloak_role.core_cd.name
  core_rd_role_name     = keycloak_role.core_rd.name
  password_seed         = var.password_seed
  password_seed_version = var.password_seed_version
}
