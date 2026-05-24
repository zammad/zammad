# Zammad — Engineering Bugs Overview

## Overview

The "Engineering Bugs" overview provides a filtered ticket list for engineering
team members working on mPorts bug reports and agent tasks.

## Configuration

| Setting | Value |
|---------|-------|
| Name | Engineering Bugs |
| URL slug | `engineering_bugs` |
| Priority | 2000 (appears after standard overviews) |
| Visible to | mPorts Engineering Agent, Agent, Admin |

## Filter Conditions

| Field | Operator | Value |
|-------|----------|-------|
| `ticket.group_id` | is | Engineering Bugs |
| `ticket.state_id` | is not | closed |

## Columns Displayed

### Desktop View

| Column | Field |
|--------|-------|
| Number | `number` |
| Title | `title` |
| State | `state` |
| Priority | `priority` |
| Severity | `mports_severity` |
| Feature Area | `mports_feature_area` |
| Environment | `mports_environment` |
| Trace ID | `mports_trace_id` |
| Agent State | `mports_agent_state` |
| PR URL | `mports_pr_url` |
| Updated | `updated_at` |

### Small/Single View

| Column | Field |
|--------|-------|
| Number | `number` |
| Title | `title` |
| State | `state` |
| Severity | `mports_severity` |
| Agent State | `mports_agent_state` |
| Updated | `updated_at` |

### Mobile View

| Column | Field |
|--------|-------|
| Number | `number` |
| Title | `title` |
| State | `state` |
| Severity | `mports_severity` |
| Updated | `updated_at` |

## Sort Order

- Sort by: `updated_at`
- Direction: Descending (most recently updated first)

## Usage

Engineers use this overview to:

1. Triage incoming bugs from mPorts
2. Monitor agent workflow progress (agent state column)
3. Review PRs (click PR URL directly from overview)
4. Identify blocked tickets
5. Track severity distribution

## Future Enhancements

Once automation is built:

- Additional filtered overviews per agent state (e.g., "Awaiting Human Review")
- SLA integration for blocker/major severity tickets
- Auto-assignment based on feature area
