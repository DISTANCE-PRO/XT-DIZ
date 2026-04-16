# distance-xt-diz

Per-site application for a single DIZ (Daten-Integrations-Zentrum) in the
distance-xt platform.

Namespace: `distance-xt-diz-<site>`

One instance of this repo is deployed per participating site. It consumes the
shared `distance-xt-core` (Keycloak, terminology server) and
`distance-xt-trust-center` (gICS, gPAS, tc-agent) services.

## Overview

![Diagram](architecture.png)

## Components

- **rp/mailbox** — Rollout Partner DSF Mailbox for data exchange.
  Internal `.local` zone only.
- **cd/hds** — Blaze FHIR server for the Clinical Domain (CD-HDS) + frontend.
  - `https://fhir-cd.${DIZ_NAME}.distance-xt.life.uni-leipzig.local`
- **cd/fts-agent** — FTS-next clinical-domain agent. Reads from CD-HDS,
  coordinates with tc-agent, pushes pseudonymized data to rd-agent.
- **rd/hds** — Blaze FHIR server for the Research Domain (RD-HDS) + frontend.
  `ENFORCE_REFERENTIAL_INTEGRITY=false` as required by FTS-next.
  - `https://fhir-rd.${DIZ_NAME}.distance-xt.life.uni-leipzig.local`
- **rd/fts-agent** — FTS-next research-domain agent. Receives pseudonymized
  data and stores it in RD-HDS.
- **fdpg/bpe** — FDPG Medical Business Process Engine for workflow coordination.
- **fdpg/mailbox** — DSF FHIR server (mailbox) + PostgreSQL. The **only
  externally reachable** service in the DIZ; all others use the internal
  `.local` zone.
  - `https://${DIZ_NAME}.distance-xt.life.uni-leipzig.de/fhir` (public `.de`)

## Site-specific configuration

`${DIZ_NAME}` is substituted by the CI pipeline (envsubst) from the
`DIZ_NAME` matrix variable. The value is the site slug, e.g. `test-1`.

## Required CI variables

Per-DIZ secrets live in a single **file-type** CI/CD variable
`CREDENTIALS_FILE`, environment-scoped (one scope per `DIZ_NAME`). Dotenv
format — `KEY=VALUE` per line, no quoting, no multi-line values.
`.app/apply` copies it to `credentials.env` and feeds it to
`kustomize edit add secret credentials --from-env-file=…`, producing a k8s
`Secret` with one data key per line.

Expected keys:

| Key                              | Purpose                                     |
|----------------------------------|---------------------------------------------|
| `CD_FRONTEND_AUTH_CLIENT_SECRET` | OIDC client secret for Blaze CD frontend    |
| `CD_FRONTEND_AUTH_SECRET`        | Random session secret for Blaze CD frontend |
| `RD_FRONTEND_AUTH_CLIENT_SECRET` | OIDC client secret for Blaze RD frontend    |
| `RD_FRONTEND_AUTH_SECRET`        | Random session secret for Blaze RD frontend |
| `CD_AGENT_CLIENT_SECRET`         | OIDC client secret for FTS cd-agent         |
| `RD_AGENT_CLIENT_SECRET`         | OIDC client secret for FTS rd-agent         |
| `DSF_DB_LIQUIBASE_USER`          | DSF PostgreSQL migration user               |
| `DSF_DB_LIQUIBASE_PASSWORD`      | DSF PostgreSQL migration password           |
| `DSF_DB_USER`                    | DSF PostgreSQL runtime user                 |
| `DSF_DB_PASSWORD`                | DSF PostgreSQL runtime password             |

## Deploy

Via the shared kustomize CI component (`util/k8s-ci/kustomize@0.3.1`). The
`app/deploy:prod` job runs automatically on the default branch and on MRs
labelled `hint::autodeploy`; otherwise it's manual.

## Open items

- DSF certificate / mTLS setup: CA bundle, server cert, role config.
- Confirm tc-agent service name and namespace for cross-namespace URLs.
- NetworkPolicy: restrict agent and DSF traffic to known peers only.
- RD ↔ FDPG-test wiring (ask @mruehle).
