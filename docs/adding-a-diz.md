# Adding a new DIZ

This guide covers onboarding a new rollout partner to the DISTANCE:PRO XT network.

## Overview

The repo is deployed once per diz as a separate GitLab environment. Each DIZ needs:

1. A unique **DIZ name** (slug, e.g. `test-1`, `leipzig-1`).
2. A unique **password seed** (the secret input for deriving all OIDC client
   secrets for that DIZ).
3. DNS records for the per-site hostnames.
4. A `KUBE_NAMESPACE` so the deploy job targets the right namespace.

The Terraform code provisions per-DIZ Keycloak resources automatically once
the seed is provided — no per-DIZ code changes are needed.

## Step-by-step

### 1. Pick a DIZ name

Lowercase, dash-separated. Used as the `DIZ_NAME` matrix variable, the Keycloak
realm name (`diz-${DIZ_NAME}`), and the per-DIZ prefix for central-realm
clients (`DIZ:${DIZ_NAME}/...`).

### 2. Generate and store a password seed

Generate a strong random seed and store it in Vault:

```sh
vault kv put secret/v1/distance/diz/${DIZ_NAME}/password_seed seed="$(openssl rand -hex 32)"
```

### 3. Register the seed in the project CI variable

Set a project-level CI/CD variable (type "Variable", masked) whose name is
the DIZ slug with all letters uppercased and `-` replaced with `_`, prefixed
with `PASSWORD_SEED_`. For example:

| DIZ slug     | CI variable name        |
|--------------|-------------------------|
| `test-1`     | `PASSWORD_SEED_TEST_1`  |
| `leipzig-1`  | `PASSWORD_SEED_LEIPZIG_1` |

The same transform is applied by `.gitlab-ci/genseeds.sh` (which builds the
`TF_VAR_password_seeds` map for `.tf/init`) and by `.gitlab-ci/genpassenv.sh`
(which derives each client secret in the per-DIZ deploy job).

### 4. Add the DIZ to the deploy matrix

In `.gitlab-ci.yml`, append the slug to the `.dizs` anchor:

```yaml
.dizs: &dizs
- test-1
- <new-diz-name>
```

The `.dizs` anchor is the single source of truth. It drives the
`app/deploy:prod` `parallel.matrix` (via `*dizs`), the Terraform `for_each`
in `main.tf`, and the seed-map build in `.tf/init`
(`.gitlab-ci/genseeds.sh`). Local dev reads the same anchor, so there is
nothing else to update.

### 5. Upload the DSF secure files

Each DIZ needs its DSF client certificate and private key bundled as a
GitLab Secure File named `${DIZ_NAME}-secrets.tar.gz` (project → Settings →
CI/CD → Secure Files). The deploy job's `.gitlab-ci/download-secrets.sh`
fetches and extracts it into `.secrets/certs`, where `create-credentials-env.sh`
and `generate-thumbprints.sh` consume the certs. The archive must contain the
`fdpg-dsf-*` and `rp-dsf-*` cert/key PEMs referenced in `.app/apply`.

### 6. Provision DNS

Create the following records (see AGENTS.md):

- `cd.${DIZ_NAME}.distance-xt.life.uni-leipzig.local`
- `rd.${DIZ_NAME}.distance-xt.life.uni-leipzig.local`
- `${DIZ_NAME}.distance-xt.life.uni-leipzig.de` (FDPG mailbox, externally
  reachable)

TLS certificates are handled by the cluster ingress.

### 7. Configure the deploy target

Each DIZ deploys to the same Forschungsnetz cluster. The `KUBE_NAMESPACE` (or
equivalent) CI/CD variable selects the namespace, which follows the pattern
`distance-xt-diz-${DIZ_NAME}`. Confirm the namespace is created, and scoped to 
the correct environment (e.g. `test-1`)

### 8. Run the pipeline

Push to the default branch. The `app/deploy:prod` job runs once per DIZ in
the `parallel.matrix`. The first run creates the per-DIZ Keycloak realm and
the central-realm service-account clients.

## Rotating the password seed

To rotate, generate a new seed and update `TF_VAR_password_seeds`. To force
Keycloak to rewrite the `client_secret_wo` values, bump the
`password_seed_version` input in `variables.tf` (default is `3`). Without
the bump, Keycloak skips the write-only secret update and stale secrets
remain.

## Local development

`.lifectlrc` reads the DIZ list from the `.dizs` anchor in `.gitlab-ci.yml`,
fetches each DIZ's seed from Vault, and exports `TF_VAR_password_seeds`. No
extra configuration is needed — adding a DIZ to `.dizs` is picked up
automatically. Requires `jq`, `yq`, and `vault` on `PATH`.

## What Terraform provisions

Per DIZ (key in `TF_VAR_password_seeds`):

- Realm `diz-${DIZ_NAME}` (per-DIZ)
- `cd-hds-frontend`, `rd-hds-frontend` clients (per-DIZ realm)
- OIDC identity provider broker to the central `distance-xt` realm (per-DIZ)
- `DIZ:${DIZ_NAME}/cd-hds`, `DIZ:${DIZ_NAME}/rd-hds` service-account clients
  (central realm) for terminology server access
- `DIZ:${DIZ_NAME}/cd-fts-agent`, `DIZ:${DIZ_NAME}/rd-fts-agent`
  service-account clients (central realm) for trust-center authentication
- `DIZ:${DIZ_NAME}/broker` client (central realm) used by the per-DIZ IdP
  (broker client_secret is random; kept in Terraform state)

All secrets except the broker client are derived deterministically from the
DIZ's `password_seed` via `sha256("PASSWORD_SEED:SECRET_NAME")` truncated to
32 characters.

## Prerequisites in the central `distance-xt` realm

The following must exist before Terraform can plan/apply:

- The realm itself (managed by the `core` repo).
- Realm roles `cd-agent`, `rd-agent` (assigned to the FTS agent service
  accounts; checked by `tc-agent`).
- Realm role `cd-admin` (created by this repo; mappable into per-DIZ realms
  via the IdP role mapper).
