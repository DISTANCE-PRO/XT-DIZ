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
}

resource "keycloak_openid_audience_protocol_mapper" "rd_hds_audience" {
  realm_id                 = keycloak_realm.diz.id
  client_id                = keycloak_openid_client.rd_hds.id
  name                     = keycloak_openid_client.rd_hds.client_id
  included_custom_audience = "rd-hds"
}
