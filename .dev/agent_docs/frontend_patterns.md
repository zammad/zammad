# Frontend Patterns

## Code Placement Rules

Code shared across both apps (desktop/mobile) lives in `app/frontend/shared/`.
Code used across multiple pages within one app goes at the app level.
Page-specific code stays in the page folder.

**Pages cannot import from other pages** (enforced by eslint).
Move shared logic up to the app or shared level.

## shared/entities/

Business logic per domain entity (e.g. ticket, user) lives in
`shared/entities/<entity>/`. This includes entity-specific composables,
GraphQL operations, entity attribute stores, client attribute definitions
(`attributes.ts`), and types.
Do not place components inside entity folders.

`shared/entities/core/` holds infrastructure across all entities, not an
entity. `core/attributes/` is the entity attributes layer: it merges the
object manager attributes from the server with the client attributes of each
entity and builds form fields, table columns, search filters and displays.

## shared/components/ — CommonXYZ Convention

Shared components follow the `CommonXYZ` naming pattern.
The folder name, Vue file name, and component name must match
(e.g. `CommonNotifications/CommonNotifications.vue`).
Related composables, types (`types.ts`), and sub-components live
inside the same folder.

## Auto-Generated Files — Never Edit

- `shared/graphql/types.ts`
- `shared/types/config.ts`
- `.ts` files next to `.graphql` operation files
  (e.g. `graphql/queries/`, `graphql/mutations/`, `graphql/subscriptions/`)
