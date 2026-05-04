# Client used by the per-DIZ realm to broker authentication to the core realm
resource "keycloak_openid_client" "core_broker" {
  realm_id  = var.core_realm_id
  client_id = "DIZ:${var.name}/broker"

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris   = ["${var.keycloak_base_url}/realms/diz-${var.name}/broker/distance-xt/endpoint"]
}

# DIZ specific clients for access of HDS instances to central terminology server
resource "keycloak_openid_client" "core_cd_hds" {
  realm_id  = var.core_realm_id
  client_id = "DIZ:${var.name}/cd-hds"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

resource "keycloak_openid_audience_protocol_mapper" "core_cd_hds_audience" {
  realm_id                 = var.core_realm_id
  client_id                = keycloak_openid_client.core_cd_hds.id
  name                     = keycloak_openid_client.core_cd_hds.client_id
  included_custom_audience = "term-server"
}

resource "keycloak_openid_client" "core_rd_hds" {
  realm_id  = var.core_realm_id
  client_id = "DIZ:${var.name}/rd-hds"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true
}

resource "keycloak_openid_audience_protocol_mapper" "core_rd_hds_audience" {
  realm_id                 = var.core_realm_id
  client_id                = keycloak_openid_client.core_rd_hds.id
  name                     = keycloak_openid_client.core_rd_hds.client_id
  included_custom_audience = "term-server"
}
