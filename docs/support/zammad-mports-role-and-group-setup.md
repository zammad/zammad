# Zammad — mPorts Engineering Role & Group Setup

## Overview

mPorts creates structured engineering bug tickets via the Zammad REST API.
This document describes the role and group configuration that supports this integration.

## Group: Engineering Bugs

| Field | Value |
|-------|-------|
| Name | Engineering Bugs |
| Purpose | Destination group for mPorts API-created bug reports |
| Users | Engineers, developer agents, reviewers |
| Separation | Distinct from generic customer support queues |

Tickets created by the mPorts "Report Issue" feature are automatically assigned to this group.

## Role: mPorts Engineering Agent

| Field | Value |
|-------|-------|
| Name | mPorts Engineering Agent |
| Signup | No (manually assigned) |
| Permissions | `ticket.agent`, `user_preferences`, `knowledge_base.reader` |
| Group access | `Engineering Bugs` → full |

### Capabilities

- View and update engineering bug tickets
- Add internal notes (not visible to customers)
- Update mPorts custom fields (trace IDs, PR links, preview URLs, verdicts)
- See all engineering metadata on tickets

### Restrictions

- Cannot administer Zammad globally
- Cannot change system settings
- Cannot delete tickets (unless system-wide policy allows)
- Cannot access groups outside Engineering Bugs (unless separately granted)

## API User Setup

For the mPorts application to create tickets programmatically:

1. Create a dedicated user (e.g., `mports-api@yourcompany.com`)
2. Assign the **Agent** role (required for API ticket creation with custom fields)
3. Assign access to the **Engineering Bugs** group
4. Generate an API token with `ticket.agent` permission scope
5. Do NOT grant Admin role

The API user acts on behalf of the customer (sets `customer` field to the real mPorts user).

## Access Matrix

| Actor | Role | Can See Engineering Fields | Can Edit Fields | Can Admin |
|-------|------|--------------------------|-----------------|-----------|
| End user (customer) | Customer | No | No | No |
| mPorts API user | Agent (scoped) | Yes | Yes | No |
| Engineering agent | mPorts Engineering Agent | Yes | Yes | No |
| Support admin | Admin | Yes | Yes | Yes |

## Manual Steps (Zammad Admin UI)

After running the migration:

1. Create the API user account in Admin → Users
2. Assign Agent role + Engineering Bugs group access
3. Generate API token in Admin → System → API → Token Access
4. Store the token securely (not in this repo)
5. Verify the Engineering Bugs overview appears for agents
