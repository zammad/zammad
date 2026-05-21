# CLAUDE.md — Zammad Repo Governance

## Purpose

This repository powers the internal ticketing/helpdesk platform based on Zammad.

Core goals:

- Stable customer support operations
- Safe AI-assisted development
- Fast iteration without breaking production
- Deterministic behavior over “smart guessing”
- Strong auditability + rollback safety

This repo follows the same operational philosophy as mPorts:

- SSOT-first
- Small PRs
- Automerge-safe lanes
- CI enforced
- No silent architectural drift
- Agent-friendly guardrails

---

# Core Engineering Principles

## 1. Source of Truth (SSOT)

Never duplicate business logic.

If logic already exists:

- extend it
- centralize it
- test it

Do NOT:

- fork behavior
- create parallel resolvers
- duplicate validation
- hardcode UI-only logic

---

## 2. Small PR Policy

Preferred PR size:

- <300 lines ideal
- <600 acceptable
- >1000 requires architectural justification

Large rewrites are forbidden unless explicitly approved.

---

## 3. Automerge Rules

Automerge allowed ONLY if ALL are true:

- CI green
- lint green
- tests green
- no migration risk
- no auth/security changes
- no infrastructure changes
- no schema-breaking changes

Automerge MUST be disabled for:

- auth
- permissions
- uploads
- email parsing
- ticket routing
- background jobs
- webhooks
- AI integrations
- infra/docker/k8s
- secrets/config

---

# Repository Structure Rules

## Allowed High-Level Structure

/docs
/apps
/packages
/scripts
/tests
/infra
/tools

Do not create random top-level folders.

---

# Documentation Lifecycle

Every meaningful feature should have:

## PRD

Why feature exists.

## Plan

Implementation phases and rollback strategy.

## Audit

What was inspected and findings.

## Spec

Behavior contract if needed.

---

# AI Agent Governance

AI agents are contributors, not architects.

Agents MAY:

- refactor
- add tests
- improve DX
- implement scoped tasks
- fix localized bugs

Agents MUST NOT:

- redesign architecture silently
- invent workflows
- create parallel systems
- bypass existing abstractions
- hardcode defaults
- delete safety checks

---

# Hardcoding Policy

Forbidden:

- hardcoded pricing
- hardcoded routing
- hardcoded IDs
- hardcoded warehouse logic
- hardcoded admin users
- hardcoded ticket statuses
- hardcoded support emails

Allowed:

- test fixtures
- constants with justification
- feature flags
- documented defaults

All defaults must live in:

- config
- env
- database settings
- typed constants

---

# Ticket System Safety Rules

## Never Lose Tickets

Changes affecting:

- inbound mail
- ticket creation
- ticket state
- attachments
- notifications
- SLAs
- automations

require:

- regression tests
- replay fixtures if possible
- rollback path

---

# Upload Safety

All uploads must:

- validate mime type
- validate size
- sanitize filenames
- avoid path traversal
- preserve audit trail

Never trust client filenames.

---

# Background Jobs

All workers/jobs must:

- be idempotent
- retry-safe
- observable
- structured logged
- correlation-id aware

No silent failures.

---

# Logging Standards

Logs must be:

- structured
- grep-friendly
- actionable

Required:

- request_id
- ticket_id when applicable
- user_id when applicable
- integration source
- failure reason

Avoid:

- noisy console spam
- giant payload dumps
- secrets in logs

---

# Security Rules

Never commit:

- secrets
- API keys
- .env files
- OAuth credentials
- SMTP passwords

Use:

- .env.example
- secret managers
- runtime injection

---

# CI Requirements

Minimum CI:

- lint
- typecheck
- unit tests
- build validation
- migration validation

Preferred:

- e2e smoke
- security scan
- dependency audit

---

# Testing Philosophy

Priority:

1. business logic
2. permissions
3. workflows
4. integrations
5. UI polish

Tests should verify:

- state transitions
- authorization
- notification behavior
- attachment handling
- webhook correctness

---

# Migration Rules

Migrations must:

- be reversible when possible
- avoid destructive changes
- include backfill strategy
- document rollout risk

Never combine:

- schema rewrite
- feature rewrite
- infra rewrite

in one PR.

---

# Branch Naming

feature/*
fix/*
audit/*
refactor/*
infra/*
docs/*
test/*

---

# Commit Naming

Examples:
fix(ticket-routing): prevent duplicate webhook creation
refactor(email-parser): centralize attachment sanitizer
audit(upload-flow): inspect attachment lifecycle
test(sla): add escalation timing coverage

---

# Reviewer Expectations

Reviewers should check:

- SSOT violations
- duplicated logic
- hidden breaking changes
- unsafe defaults
- missing tests
- architectural drift

---

# Operational Philosophy

This repo optimizes for:

- long-term maintainability
- operational stability
- safe AI collaboration
- deterministic workflows
- auditability
- rollback safety

Not for:

- clever abstractions
- premature microservices
- uncontrolled AI coding
- magic behavior
