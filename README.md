# distance-xt-diz

Per-site FHIR data store for a single DIZ (Daten-Integrations-Zentrum) in the
distance-xt platform.

Namespace: `distance-xt-diz-<site>`

One instance of this repo is deployed per participating site. It consumes the
shared `distance-xt-core` (Keycloak, terminology server) and
`distance-xt-trust-center` (gICS, gPAS) services.

## Components

- **blaze** — Blaze FHIR server storing the site's patient/study data.
  - Backend: `https://fhir.diz-<site>.distance-xt.life.uni-leipzig.local/fhir`
  - Frontend: `https://fhir.diz-<site>.distance-xt.life.uni-leipzig.local`

## Site-specific configuration

Search for `diz-example` in the manifests and replace with the actual site slug
(e.g. `diz-uol`, `diz-ukl`). Affected files:

- `blaze/backend/ing.yml` — `BASE_URL` env + ingress host
- `blaze/frontend/ing.yml` — ingress host
- `blaze/frontend/depl.yml` — `ORIGIN`, `AUTH_ISSUER` env

## Required CI variables

The `credentials` secret is assembled by CI (`.app/apply` in `.gitlab-ci.yml`)
from these GitLab CI/CD variables:

- `FRONTEND_AUTH_CLIENT_SECRET` — OIDC client secret for the Blaze UI
- `FRONTEND_AUTH_SECRET` — random session secret (`openssl rand -hex 32`)

## Deploy

Via the shared kustomize CI component (`util/k8s-ci/kustomize@0.3.1`). The
`app/deploy:prod` job runs automatically on the default branch and on MRs
labelled `hint::autodeploy`; otherwise it's manual.

## Open items

- Confirm per-DIZ Keycloak client names and realm (currently assumes realm
  `distance-xt` in shared core Keycloak).
- Decide on storage size and StorageClass for the data PVC per site.
- NetworkPolicy: restrict Blaze inbound to trust-center agents + ingress only.
- Consider `ENABLE_ADMIN_API` — disable in prod once data is loaded.
