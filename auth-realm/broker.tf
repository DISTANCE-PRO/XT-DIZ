# Identity brokering: per-DIZ realm delegates authentication to the core realm.
# Users are managed centrally in the core "distance-xt" realm and brokered into
# each per-DIZ realm on first login.

# --- Identity Provider ---

resource "keycloak_oidc_identity_provider" "core" {
  realm         = keycloak_realm.diz.id
  alias         = "distance-xt"
  display_name  = "DISTANCE:PRO XT"
  provider_id   = "keycloak-oidc"
  client_id     = keycloak_openid_client.core_broker.client_id
  client_secret = keycloak_openid_client.core_broker.client_secret
  trust_email   = true
  sync_mode     = "FORCE"

  authorization_url = "${var.keycloak_base_url}/realms/distance-xt/protocol/openid-connect/auth"
  token_url         = "${var.keycloak_base_url}/realms/distance-xt/protocol/openid-connect/token"
  user_info_url     = "${var.keycloak_base_url}/realms/distance-xt/protocol/openid-connect/userinfo"
  jwks_url          = "${var.keycloak_base_url}/realms/distance-xt/protocol/openid-connect/certs"
  logout_url        = "${var.keycloak_base_url}/realms/distance-xt/protocol/openid-connect/logout"
  issuer            = "${var.keycloak_base_url}/realms/distance-xt"

  first_broker_login_flow_alias = keycloak_authentication_flow.first_broker_login.alias

  extra_config = {
    "clientAuthMethod" = "client_secret_post"
  }
}

# --- Browser flow: auto-redirect to core IdP ---

resource "keycloak_authentication_flow" "browser" {
  realm_id    = keycloak_realm.diz.id
  alias       = "browser-idp"
  description = "Browser flow that auto-redirects to the core identity provider"
}

resource "keycloak_authentication_execution" "browser_cookie" {
  realm_id          = keycloak_realm.diz.id
  parent_flow_alias = keycloak_authentication_flow.browser.alias
  authenticator     = "auth-cookie"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

resource "keycloak_authentication_execution" "browser_idp_redirector" {
  realm_id          = keycloak_realm.diz.id
  parent_flow_alias = keycloak_authentication_flow.browser.alias
  authenticator     = "identity-provider-redirector"
  requirement       = "ALTERNATIVE"
  priority          = 20
}

resource "keycloak_authentication_execution_config" "browser_idp_redirector" {
  realm_id     = keycloak_realm.diz.id
  execution_id = keycloak_authentication_execution.browser_idp_redirector.id
  alias        = "distance-xt-redirector"
  config = {
    defaultProvider = keycloak_oidc_identity_provider.core.alias
  }
}

# --- First broker login flow: auto-create or auto-link accounts ---

resource "keycloak_authentication_flow" "first_broker_login" {
  realm_id    = keycloak_realm.diz.id
  alias       = "first-broker-login-auto-link"
  description = "Auto-creates or auto-links brokered users without prompting"
}

resource "keycloak_authentication_execution" "create_user_if_unique" {
  realm_id          = keycloak_realm.diz.id
  parent_flow_alias = keycloak_authentication_flow.first_broker_login.alias
  authenticator     = "idp-create-user-if-unique"
  requirement       = "ALTERNATIVE"
  priority          = 10
}

resource "keycloak_authentication_subflow" "handle_existing" {
  realm_id          = keycloak_realm.diz.id
  parent_flow_alias = keycloak_authentication_flow.first_broker_login.alias
  alias             = "handle-existing-account"
  provider_id       = "basic-flow"
  requirement       = "ALTERNATIVE"
  priority          = 20
}

resource "keycloak_authentication_execution" "auto_link" {
  realm_id          = keycloak_realm.diz.id
  parent_flow_alias = keycloak_authentication_subflow.handle_existing.alias
  authenticator     = "idp-auto-link"
  requirement       = "REQUIRED"
  priority          = 10
}

# --- Bind custom flows to realm ---

resource "keycloak_authentication_bindings" "diz" {
  realm_id     = keycloak_realm.diz.id
  browser_flow = keycloak_authentication_flow.browser.alias
}
