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

The default slot of the desktop `CommonLoader` takes exactly one root
element. It renders inside a `<Transition>`, which shows only the first
element in the app. Vitest stubs transitions and renders every sibling, so
a spec passes while the app drops content.

## Script Conventions

- Declare reactive state with `ref()`, also for objects, arrays, maps and
  sets (`ref(new Map())`). `reactive()` is not used in new code (enforced
  by eslint).
- Composables, helpers and stores use named exports and `const` arrow
  functions: `export const useExample = () => { … }`. Modules a registry
  loads through `import.meta.glob` (form fields, routes, plugins) keep the
  default export the registry reads.
- When the callers of a shared builder or composable differ in switches
  that are exact inverses of each other (`withTags: true, withVisibility:
  false` and the reverse), take one option that names the variant
  (`edit: boolean`). Separate booleans allow combinations that do not exist.

## Form System

Ticket create and edit have the hardest cases of dirty state, reset and
core workflow solved. Before adding behaviour to
`shared/components/Form/` or to the form updater
(`app/models/form_updater/`), read how they handle the same situation
(`shared/entities/ticket/composables/useTicketEdit.ts`). Before concluding
that the form is at fault, make the form updater mock of the spec send what
the backend sends, `initialValue` included.

## Auto-Generated Files — Never Edit

- `shared/graphql/types.ts`
- `shared/types/config.ts`
- `.ts` files next to `.graphql` operation files
  (e.g. `graphql/queries/`, `graphql/mutations/`, `graphql/subscriptions/`)

## GraphQL Operations

Call a generated composable with **one options object** and wrap it in a
handler from `#shared/server/apollo/handler/index.ts` (`QueryHandler`,
`MutationHandler`, `SubscriptionHandler`), which takes care of the error
handling:

```ts
const userQuery = new QueryHandler(
  useUserQuery({
    variables: { userId },
    enabled: () => props.active,
    fetchPolicy: 'cache-first',
  }),
)
```

- Only `variables` and `enabled` are reactive, every other option
  (`fetchPolicy`, `context`, …) is read once. Pass a ref where one is at
  hand, for the flag (`enabled: isEnabled`) or per variable
  (`variables: { userId }`). Use a getter for props and derived values
  (`variables: () => ({ userId: props.userId })`) and a plain object when
  nothing changes.
- A lazy query (`useXLazyQuery`) has no `enabled`: it waits for `load()`.
  `load()` starts the query synchronously, so set the state its variables
  read before the call. The composable's `load()` returns a Promise,
  `QueryHandler.load()` returns nothing. Await `QueryHandler.query()` for a
  one-off result: it works on a lazy query only, resolves `{ data, error }`
  and shows no notification when it fails.
- Mutation variables go to `send(variables)`. Variables set in the options
  are defaults which `send()` merges its own into.
- The `onResult` callback of a handler receives an object (`{ data }`), the
  `onResult` of the composable receives the data itself. Register callbacks
  on the handler.
- Never write to an Apollo result, a mutation result included. The object is
  shared with the cache: writing throws where results are frozen
  (development and Vitest) and corrupts the cached data unnoticed in a
  production build. Copy it first.

## UI Principles

- Icon-only buttons need `v-tooltip` supplying the accessible name.
- Hover/focus-only visible actions need to display on touch fallback
- Responsive grids should adapt to their container
- A fixed header above scrolling content: put the header and the content
  next to each other in a flex column of fixed height and give the content
  `overflow-y-auto`. No `position: sticky` on the header and no measuring
  of its height.
- An accessibility fix covers the desktop and the mobile app. Check the
  counterpart of the component in the other app, and leave it alone only
  when it does not have the problem.
- Translatable strings: use complete, meaningful source strings,
  sentence case for English source strings, and check for existing
  near-duplicate strings before adding new ones.
- Red marks the point of no return: `danger` and `remove` stay only on
  controls that act immediately. A trigger that only opens a confirmation
  dialog or a confirming flyout is not red: a button becomes `tertiary`
  with an icon naming the action (`trash3` for delete and discard,
  `arrow-counterclockwise` for reset), a menu item carries no variant, a
  `remove` icon button keeps its icon and takes the variant UX names per
  place. The decisive button in the dialog or flyout is `danger`.
