# Zammad — mPorts Custom Ticket Fields

## Overview

These custom fields are added to the Ticket object to support structured engineering
bug intake from the mPorts application. All fields are prefixed with `mports_` to
avoid collisions with Zammad core fields.

## Field Categories

### Core Debugging Fields

| Field Name | Type | Purpose |
|-----------|------|---------|
| `mports_trace_id` | input | Distributed trace ID for request correlation |
| `mports_request_id` | input | HTTP request ID from mPorts backend |
| `mports_session_id` | input | User session ID at time of report |
| `mports_environment` | select | Environment where bug occurred |
| `mports_tenant_id` | input | Multi-tenant isolation identifier |
| `mports_user_id` | input | mPorts internal user ID |
| `mports_user_email` | input | User email at time of report |
| `mports_user_role` | select | User's role in mPorts |
| `mports_page_url` | input | URL where the issue occurred |
| `mports_feature_area` | select | Product area classification |
| `mports_severity` | select | Engineering severity assessment |
| `mports_build_sha` | input | Git SHA of deployed build |
| `mports_browser` | input | Browser user-agent string |
| `mports_ticket_type` | select | Ticket classification |

### Agent Workflow Fields

| Field Name | Type | Purpose |
|-----------|------|---------|
| `mports_agent_approved` | select | Whether an AI agent may work on this ticket |
| `mports_agent_state` | select | Current state in the agent workflow pipeline |
| `mports_workspace_slot` | input | Conductor workspace slot assigned |
| `mports_branch_name` | input | Git branch for the fix |
| `mports_preview_url` | input | Preview/staging URL for the fix |
| `mports_pr_url` | input | Pull request URL |
| `mports_reviewer_verdict` | select | Code reviewer outcome |
| `mports_qa_verdict` | select | QA tester outcome |

### Business Context Fields

| Field Name | Type | Purpose |
|-----------|------|---------|
| `mports_order_id` | input | Related order ID |
| `mports_shipment_id` | input | Related shipment ID |
| `mports_po_id` | input | Related purchase order ID |
| `mports_sku` | input | Related SKU |
| `mports_warehouse_id` | input | Related warehouse ID |
| `mports_integration_name` | input | External integration name |
| `mports_integration_job_id` | input | External integration job ID |

## Dropdown Values

### mports_ticket_type

- `support` — General support request
- `bug` — Software defect
- `feature_request` — Feature request
- `agent_task` — Task for AI agent
- `architecture_review` — Architecture review request

### mports_environment

- `local` — Local development
- `staging` — Staging environment
- `production` — Production
- `agent_preview` — Agent preview deployment

### mports_user_role

- `public` — Unauthenticated visitor
- `buyer` — Buyer account
- `seller` — Seller account
- `admin` — Admin account
- `internal` — Internal team member

### mports_feature_area

- `public_portal` — Public-facing portal
- `buyer_portal` — Buyer dashboard
- `seller_portal` — Seller dashboard
- `admin_portal` — Admin panel
- `checkout` — Checkout flow
- `cart` — Shopping cart
- `orders` — Order management
- `bas_buy_and_store` — Buy and Store (BAS)
- `stored_inventory` — Stored inventory management
- `warehouse_release` — Warehouse release flow
- `bulk_upload` — Bulk upload feature
- `shipping_docs` — Shipping documents
- `inventory` — Inventory management
- `warehouse_routing` — Warehouse routing logic
- `pricing` — Pricing engine
- `payments` — Payment processing
- `integrations` — Third-party integrations
- `reporting` — Reports and analytics
- `auth` — Authentication/authorization
- `tenant_isolation` — Multi-tenant isolation
- `other` — Other / uncategorized

### mports_severity

- `blocker` — System unusable, no workaround
- `major` — Core feature broken, workaround exists
- `minor` — Non-critical issue
- `cosmetic` — Visual/UX polish

### mports_agent_approved

- `false` — Not approved for agent work
- `true` — Approved for agent work

### mports_agent_state

- `not_approved` — Awaiting human approval
- `agent_approved` — Approved, not yet started
- `workspace_created` — Conductor workspace created
- `builder_running` — Builder agent executing
- `builder_done` — Builder agent complete
- `reviewer_running` — Reviewer agent executing
- `reviewer_passed` — Reviewer approved
- `qa_running` — QA agent executing
- `qa_passed` — QA approved
- `pr_ready` — PR created, ready for human review
- `human_review` — Awaiting human merge decision
- `blocked` — Blocked (see notes)
- `closed` — Workflow complete

### mports_reviewer_verdict

- `none` — Not yet reviewed
- `PASS` — Approved
- `WARN` — Approved with warnings
- `BLOCK` — Blocked, requires changes

### mports_qa_verdict

- `none` — Not yet tested
- `PASS` — All checks pass
- `WARN` — Passes with warnings
- `BLOCK` — QA failed

## Tags

The following tags should exist for filtering and automation:

| Tag | Purpose |
|-----|---------|
| `mports` | All mPorts-originated tickets |
| `bug` | Bug reports |
| `engineering` | Engineering-relevant tickets |
| `agent_candidate` | Eligible for AI agent work |
| `agent_approved` | Approved for AI agent work |
| `blocked` | Blocked tickets |
| `qa_failed` | QA verdict was BLOCK |
| `reviewer_blocked` | Reviewer verdict was BLOCK |

Tags are created on first use in Zammad. The mPorts API should include relevant tags
when creating tickets.

## Screen Visibility

All mPorts custom fields are visible on:

- **Agent create screen** (optional, nullable)
- **Agent edit screen** (optional, nullable)

They are NOT shown on:

- Customer create screen
- Customer portal

This keeps the customer-facing experience simple while giving agents full metadata.
