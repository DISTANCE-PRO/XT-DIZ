data "keycloak_realm" "distance_xt" {
  realm = "distance-xt"
}

locals {
  keycloak_base_url = "https://auth.distance-xt.life.uni-leipzig.local"
  dizs              = toset(yamldecode(file(".gitlab-ci.yml"))[".dizs"])
}

module "auth_realm" {
  for_each          = local.dizs
  source            = "./auth-realm"
  name              = each.key
  core_realm_id     = data.keycloak_realm.distance_xt.id
  keycloak_base_url = local.keycloak_base_url
}
