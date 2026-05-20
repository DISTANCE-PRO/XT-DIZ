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

  client_secret_wo         = substr(sha256("${var.password_seed}:CD_HDS_BACKEND_AUTH_CLIENT_SECRET"), 0, 32)
  client_secret_wo_version = var.password_seed_version
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

  client_secret_wo         = substr(sha256("${var.password_seed}:RD_HDS_BACKEND_AUTH_CLIENT_SECRET"), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_audience_protocol_mapper" "core_rd_hds_audience" {
  realm_id                 = var.core_realm_id
  client_id                = keycloak_openid_client.core_rd_hds.id
  name                     = keycloak_openid_client.core_rd_hds.client_id
  included_custom_audience = "term-server"
}

# FTS agents: service-to-service authentication to trust-center-agent.
# tc-agent validates the token and checks the "cd" / "rd" realm role.
resource "keycloak_openid_client" "core_cd_fts_agent" {
  realm_id  = var.core_realm_id
  client_id = "DIZ:${var.name}/cd-fts-agent"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true

  client_secret_wo         = substr(sha256("${var.password_seed}:CD_FTS_TC_CLIENT_SECRET"), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_client_service_account_realm_role" "core_cd_fts_agent_role" {
  realm_id                = var.core_realm_id
  service_account_user_id = keycloak_openid_client.core_cd_fts_agent.service_account_user_id
  role                    = var.core_cd_role_name
}

resource "keycloak_openid_client" "core_rd_fts_agent" {
  realm_id  = var.core_realm_id
  client_id = "DIZ:${var.name}/rd-fts-agent"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true

  client_secret_wo         = substr(sha256("${var.password_seed}:RD_FTS_TC_CLIENT_SECRET"), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_client_service_account_realm_role" "core_rd_fts_agent_role" {
  realm_id                = var.core_realm_id
  service_account_user_id = keycloak_openid_client.core_rd_fts_agent.service_account_user_id
  role                    = var.core_rd_role_name
}
