resource "keycloak_realm" "diz" {
  realm = "diz-${var.name}"
}

resource "keycloak_openid_client" "cd_hds" {
  realm_id  = keycloak_realm.diz.id
  client_id = "cd-hds-frontend"

  root_url            = "https://cd.${var.name}.distance-xt.life.uni-leipzig.local/fhir"
  valid_redirect_uris = ["https://cd.${var.name}.distance-xt.life.uni-leipzig.local/fhir/*"]

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true

  client_secret_wo         = substr(base64encode(sha256("${var.password_seed}:CD_HDS_FRONTEND_AUTH_CLIENT_SECRET")), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_audience_protocol_mapper" "cd_hds_audience" {
  realm_id                 = keycloak_realm.diz.id
  client_id                = keycloak_openid_client.cd_hds.id
  name                     = keycloak_openid_client.cd_hds.client_id
  included_custom_audience = "cd-hds"
}

resource "keycloak_openid_client" "rd_hds" {
  realm_id  = keycloak_realm.diz.id
  client_id = "rd-hds-frontend"

  root_url            = "https://rd.${var.name}.distance-xt.life.uni-leipzig.local/fhir"
  valid_redirect_uris = ["https://rd.${var.name}.distance-xt.life.uni-leipzig.local/fhir/*"]

  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true

  client_secret_wo         = substr(base64encode(sha256("${var.password_seed}:RD_HDS_FRONTEND_AUTH_CLIENT_SECRET")), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_audience_protocol_mapper" "rd_hds_audience" {
  realm_id                 = keycloak_realm.diz.id
  client_id                = keycloak_openid_client.rd_hds.id
  name                     = keycloak_openid_client.rd_hds.client_id
  included_custom_audience = "rd-hds"
}

# FTS agents: clinical domain and research domain (per-DIZ realm)
resource "keycloak_openid_client" "local_cd_fts_agent" {
  realm_id  = keycloak_realm.diz.id
  client_id = "cd-fts-agent"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true

  client_secret_wo         = substr(base64encode(sha256("${var.password_seed}:CD_FTS_AGENT_CLIENT_SECRET")), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_role" "cd_agent" {
  realm_id = keycloak_realm.diz.id
  name     = "cd-agent"
}

resource "keycloak_openid_client_service_account_realm_role" "local_cd_fts_agent_role" {
  realm_id                = keycloak_realm.diz.id
  service_account_user_id = keycloak_openid_client.local_cd_fts_agent.service_account_user_id
  role                    = keycloak_role.cd_agent.name
}

resource "keycloak_openid_audience_protocol_mapper" "cd_fts_agent_audience" {
  realm_id                 = keycloak_realm.diz.id
  client_id                = keycloak_openid_client.local_cd_fts_agent.id
  name                     = "cd-hds-audience"
  included_custom_audience = "cd-hds"
}

resource "keycloak_openid_client" "local_rd_fts_agent" {
  realm_id  = keycloak_realm.diz.id
  client_id = "rd-fts-agent"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true

  client_secret_wo         = substr(base64encode(sha256("${var.password_seed}:RD_FTS_AGENT_CLIENT_SECRET")), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_client_service_account_realm_role" "local_rd_fts_agent_role" {
  realm_id                = keycloak_realm.diz.id
  service_account_user_id = keycloak_openid_client.local_rd_fts_agent.service_account_user_id
  role                    = keycloak_role.cd_agent.name
}

resource "keycloak_openid_audience_protocol_mapper" "rd_fts_agent_audience" {
  realm_id                 = keycloak_realm.diz.id
  client_id                = keycloak_openid_client.local_rd_fts_agent.id
  name                     = "rd-hds-audience"
  included_custom_audience = "rd-hds"
}

# Realm roles for the per-DIZ realm.
resource "keycloak_role" "cd_admin" {
  realm_id = keycloak_realm.diz.id
  name     = "cd-admin"
}

# FTS scheduler: service account for CronJob-triggered pipeline runs
resource "keycloak_openid_client" "fts_scheduler" {
  realm_id  = keycloak_realm.diz.id
  client_id = "fts-scheduler"

  access_type              = "CONFIDENTIAL"
  service_accounts_enabled = true

  client_secret_wo         = substr(base64encode(sha256("${var.password_seed}:FTS_SCHEDULER_CLIENT_SECRET")), 0, 32)
  client_secret_wo_version = var.password_seed_version
}

resource "keycloak_openid_client_service_account_realm_role" "fts_scheduler_cd_admin" {
  realm_id                = keycloak_realm.diz.id
  service_account_user_id = keycloak_openid_client.fts_scheduler.service_account_user_id
  role                    = keycloak_role.cd_admin.name
}
