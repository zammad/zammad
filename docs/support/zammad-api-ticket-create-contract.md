# Zammad — mPorts API Ticket Create Contract

## Overview

This document defines the exact API payloads the mPorts application uses to create
and update engineering bug tickets in Zammad.

## Authentication

All API requests use token-based authentication:

```http
Authorization: Token token=<ZAMMAD_API_TOKEN>
```

The token belongs to a scoped API user with `ticket.agent` permission and access to
the `Engineering Bugs` group. It does NOT have admin permissions.

## 1. Create Ticket

### Endpoint

```http
POST /api/v1/tickets
Content-Type: application/json
```

### Payload

```json
{
  "title": "Cart total shows $0 after adding item on buyer portal",
  "group": "Engineering Bugs",
  "customer": "buyer@example.com",
  "tags": "mports,bug,engineering",
  "article": {
    "subject": "Cart total shows $0 after adding item on buyer portal",
    "body": "## Steps to Reproduce\n1. Log in as buyer\n2. Add item SKU-1234 to cart\n3. Cart total displays $0.00\n\n## Expected\nCart total should reflect item price.\n\n## Actual\nTotal stays at $0.00.",
    "type": "note",
    "internal": false
  },
  "mports_trace_id": "tr-abc123-def456",
  "mports_request_id": "req-789xyz",
  "mports_session_id": "sess-abc",
  "mports_environment": "production",
  "mports_tenant_id": "tenant-acme",
  "mports_user_id": "usr-12345",
  "mports_user_email": "buyer@example.com",
  "mports_user_role": "buyer",
  "mports_page_url": "https://app.mports.com/buyer/cart",
  "mports_feature_area": "cart",
  "mports_severity": "major",
  "mports_build_sha": "a1b2c3d4e5f6",
  "mports_browser": "Chrome/125.0 macOS 15.4",
  "mports_ticket_type": "bug",
  "mports_agent_state": "not_approved",
  "mports_agent_approved": "false"
}
```

### Response (201 Created)

```json
{
  "id": 42,
  "number": "10042",
  "title": "Cart total shows $0 after adding item on buyer portal",
  "group_id": 2,
  "state_id": 1,
  "priority_id": 2,
  "customer_id": 5,
  "mports_trace_id": "tr-abc123-def456",
  "mports_ticket_type": "bug",
  "...": "..."
}
```

### Notes

- `customer` can be an email address — Zammad will find or create the user
- Custom fields are set as top-level keys (same level as `title`, `group`)
- Tags are comma-separated in a single string
- The initial article `internal: false` makes it visible to the customer
- The group name (not ID) can be used in the payload

## 2. Upload Screenshot Attachment

Attachments are sent as part of the article when creating the ticket, or added to
a follow-up article.

### Option A: Inline with Ticket Creation

```json
{
  "title": "Button misaligned on checkout",
  "group": "Engineering Bugs",
  "customer": "buyer@example.com",
  "article": {
    "subject": "Button misaligned on checkout",
    "body": "See attached screenshot.",
    "type": "note",
    "internal": false,
    "attachments": [
      {
        "filename": "screenshot-2024-01-15.png",
        "data": "<base64-encoded-file-content>",
        "mime-type": "image/png"
      }
    ]
  },
  "mports_ticket_type": "bug",
  "mports_severity": "cosmetic",
  "mports_feature_area": "checkout"
}
```

### Option B: Add Attachment via Follow-up Article

```http
POST /api/v1/ticket_articles
Content-Type: application/json
```

```json
{
  "ticket_id": 42,
  "subject": "Screenshot evidence",
  "body": "Attached screenshot showing the issue.",
  "type": "note",
  "internal": false,
  "attachments": [
    {
      "filename": "screenshot.png",
      "data": "<base64-encoded-file-content>",
      "mime-type": "image/png"
    }
  ]
}
```

### Attachment Limits

- Zammad default max attachment size: 10 MB
- Supported types: any (validated server-side)
- Base64 encoding increases payload size by ~33%

## 3. Add Internal Note

Internal notes are visible only to agents, not customers.

### Endpoint

```http
POST /api/v1/ticket_articles
Content-Type: application/json
```

### Payload

```json
{
  "ticket_id": 42,
  "body": "Root cause identified: price calculation skips items added via quick-add. Fix in PR #567.",
  "type": "note",
  "internal": true
}
```

### Use Cases

- Agent recording debug findings
- Developer agent logging investigation results
- Linking to relevant logs or traces
- Recording decisions about fix approach

## 4. Agent Update (PR URL, Preview URL, Verdicts)

When a developer agent progresses through the workflow, it updates the ticket's
custom fields.

### Endpoint

```http
PUT /api/v1/tickets/42
Content-Type: application/json
```

### Payload: Agent Starts Work

```json
{
  "mports_agent_state": "workspace_created",
  "mports_workspace_slot": "agent-3",
  "mports_branch_name": "fix/cart-total-zero"
}
```

### Payload: PR Ready

```json
{
  "mports_agent_state": "pr_ready",
  "mports_pr_url": "https://github.com/org/repo/pull/567",
  "mports_preview_url": "https://preview-agent-3.mports.dev",
  "mports_branch_name": "fix/cart-total-zero"
}
```

### Payload: Reviewer Verdict

```json
{
  "mports_agent_state": "reviewer_passed",
  "mports_reviewer_verdict": "PASS"
}
```

### Payload: QA Verdict

```json
{
  "mports_agent_state": "qa_passed",
  "mports_qa_verdict": "PASS"
}
```

### Payload: Blocked

```json
{
  "mports_agent_state": "blocked",
  "mports_reviewer_verdict": "BLOCK"
}
```

## 5. Business Context (Optional Fields)

When the bug relates to specific business entities, include them:

```json
{
  "title": "Order #ORD-5678 stuck in processing",
  "group": "Engineering Bugs",
  "customer": "seller@example.com",
  "mports_ticket_type": "bug",
  "mports_order_id": "ORD-5678",
  "mports_shipment_id": "SHP-9012",
  "mports_warehouse_id": "WH-LAX-01",
  "mports_feature_area": "orders",
  "mports_severity": "major"
}
```

## 6. Tag Management

### Add Tags on Creation

Include in the ticket creation payload:

```json
{
  "tags": "mports,bug,engineering,agent_candidate"
}
```

### Update Tags Later

```http
PUT /api/v1/tags
Content-Type: application/json
```

```json
{
  "object": "Ticket",
  "o_id": 42,
  "item": "agent_approved"
}
```

## Error Handling

| Status | Meaning | Action |
|--------|---------|--------|
| 201 | Created successfully | Store ticket ID |
| 401 | Invalid/expired token | Refresh token |
| 403 | Insufficient permissions | Check API user role/group |
| 422 | Validation error | Check required fields |
| 500 | Server error | Retry with backoff |

## Rate Limits

Zammad does not enforce API rate limits by default, but the mPorts integration
should self-limit to avoid overloading:

- Max 10 ticket creates/minute
- Max 60 updates/minute
- Batch screenshots into single articles where possible
