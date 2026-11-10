<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

# GraphQL document extensions

Lets an addon extend a core `.graphql` document (add fields to a query,
attach a fragment to a union result) **without editing the core file** — by
dropping extension `.graphql` files next to it. The merge happens once, at
`pnpm generate-graphql-api` time, via a graphql-codegen
[document transform](https://the-guild.dev/graphql/codegen/plugins/presets/preset-near-operation-files#adding-custom-document-transformations),
so the generated `.api.ts`, `types.ts` and `.mocks.ts` all contain the merged
operation and types — nothing extra happens at runtime. With no extension
files present, generated output is byte-identical to today.

## How it works

| File               | Role                                                                                                               |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `transform.js`     | The codegen `documentTransform`: for each document, reads its sibling `.extensions/` dir (if any) and merges it in |
| `mergeDocument.js` | Pure AST merge (no filesystem access) — testable in isolation                                                      |

Wired into `.graphql_code_generator.js` via `documentTransforms: [graphqlDocumentExtensionsTransform]`
on every document-consuming output (`types.ts`, the near-operation-file
preset, and both mocker presets). Extension files themselves are excluded
from the codegen `documents` globs (`!**/*.extensions/**`), so they never
generate their own `.api.ts`/`.mocks.ts`.

## Convention

For a base document `…/queries/quickSearch.graphql`, extensions live in
`…/queries/quickSearch.extensions/*.graphql` — a generic, sibling-directory
convention that works for any base document anywhere under `app/frontend`.
Files are merged in filename order (sorted), so name them so that matters
(e.g. `01-…`, `02-…`) if load order is ever significant.

An extension file may contain:

- **One operation definition** (same operation type as the base — a
  `mutation` extension file can't extend a `query` base) — its root
  selections are appended to the base operation's selection set, and its
  variables are merged in (deduplicated by name; the base document wins on a
  conflict, provided the type matches — a same-named variable declared with a
  _different_ type fails the build; differing default values are fine). The
  extension operation's own name is discarded.
- **One fragment definition** — the fragment is appended to the document, and
  a spread is inserted into every union/interface selection set whose possible
  types include the fragment's type condition (resolved against the schema, not
  by name matching). Object-typed selection sets are never targets, so the
  spread lands once per union position — not additionally inside a nested
  `... on X` block, nor inside another extension fragment's body. A fragment
  that matches no union/interface position fails the build as a dead extension.

Anything else (a duplicate root field — against the base document or another
extension —, a duplicate fragment name, a fragment that matches no selection
set, an operation-type or variable-type conflict, a non-field root selection,
or any other definition kind) fails the build loudly, naming the offending
extension file.

### Example: adding a searchable type to the quick search

An addon whose `ProjectBaller::Project` model is already searchable on the
backend (registered through the extension directory of the search result
union, `app/graphql/gql/types/search_result/item_type/extensions/`) needs two
frontend files, and no core edit.

Fragment — `quickSearch.extensions/projectBallerProject.graphql`:

```graphql
fragment projectBallerProjectQuickSearch on ProjectBallerProject {
  id
  internalId
  name
}
```

`ProjectBallerProject` is a member of the `Item` union returned by the
`items` field of `searchGrouped`, so the transform inserts
`...projectBallerProjectQuickSearch` there, next to the core types' inline
fragments. The fragment only adds the fields the result row renders.

Plugin — `apps/desktop/components/Search/plugins/projectBallerProject.ts`:

```ts
import { EnumSearchableModels } from '#shared/graphql/types.ts'

import ProjectBallerProject from '../QuickSearch/entities/ProjectBallerProject.vue'

import type { SearchPlugin } from '../types.ts'

export default <SearchPlugin>{
  name: EnumSearchableModels.ProjectBallerProject,
  label: __('Project'),
  priority: 500,
  quickSearchResultLabel: __('Found projects'),
  quickSearchComponent: ProjectBallerProject,
  permissions: ['ticket.agent'],
  filtersDisabled: true,
}
```

The plugin is what requests the group: its `name` puts the type into the
document's `onlyIn` list, and the result list matches the answered group to
the plugin by that same value. The enum value is the encoded model name
(`ProjectBaller__Project`); codegen turns it into the key
`ProjectBallerProject`, and both exist only once the addon's schema has been
generated, which package install does. `priority` orders the group among the
others, `permissions` (or `show`) decides who gets it. The row component
(next to the core ones in `QuickSearch/entities/`) receives `item` and `mode`
(`QuickSearchPluginProps`). The plugin also gets a tab in the detail search,
which stays empty until `detailSearchHeaders` and `detailSearchComponent` are
set and the detail search document is extended like below; the quick search
links to that tab when a group has more results than it shows.

### Example: adding a root field (operation extension)

Base — `userOverview.graphql` (illustrative, not a core document):

```graphql
query userOverview($userId: ID!) {
  user(userId: $userId) {
    id
    fullname
  }
}
```

Extension — `userOverview.extensions/projectBaller.graphql`:

```graphql
query userOverviewProjectBallerProjects($userId: ID!) {
  projectBallerProjects(userId: $userId) {
    id
    name
  }
}
```

Merged operation (what codegen actually sees — still named `userOverview`;
`$userId` is deduplicated, not doubled):

```graphql
query userOverview($userId: ID!) {
  user(userId: $userId) {
    id
    fullname
  }
  projectBallerProjects(userId: $userId) {
    id
    name
  }
}
```

### Example: attaching a fragment to a union field

Extension — `detailSearch.extensions/projectBallerProject.graphql`:

```graphql
fragment projectBallerProjectDetailSearch on ProjectBallerProject {
  name
  projectNumber
}
```

`ProjectBallerProject` is a member of the `Item` union returned by
`detailSearch`'s `items` field, so the transform appends the fragment
definition and inserts `...projectBallerProjectDetailSearch` into that
field's selection set — no core edit, and no manual "which selection set"
bookkeeping in the addon itself.

## Extension points in practice

The mechanism is generic — any base `.graphql` document can grow an
`.extensions/` sibling. The places an addon typically extends, and the UI
registry that pairs with each (all discovered via `import.meta.glob`, so an
addon only ever adds files):

| Place                | Base document                                                                                                                    | Paired UI registry                                                     |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| Quick search         | `apps/desktop/components/Search/graphql/queries/quickSearch.graphql` (fragment, spread into `searchGrouped` `items`)             | `apps/desktop/components/Search/plugins/`                              |
| Detail search        | `apps/desktop/components/Search/graphql/queries/detailSearch.graphql` (fragment on the entity type)                              | `apps/desktop/components/Search/plugins/`                              |
| Online notifications | `shared/entities/online-notification/graphql/queries/onlineNotifications.graphql` (fragment, spread into `metaObject`)           | `shared/composables/activity-message/activityMessageBuilder/builders/` |
| Taskbar tabs         | `apps/desktop/entities/user/current/graphql/fragments/userCurrentTaskbarItemAttributes.graphql` (fragment, spread into `entity`) | `apps/desktop/components/UserTaskbarTabs/plugins/`                     |

Extending the shared taskbar fragment covers the item-list query, its
subscription and mutations at once — they all import that fragment.

### Migrating a quick search operation extension

The quick search used to request every type through its own aliased `search`
root field, and an addon extended it with an operation extension adding one
more, read by the plugin's `quickSearchResultKey`. The document now asks a
single `searchGrouped` field for all types. An operation extension shipped for
the old shape still merges and compiles, but nothing reads its field any
more, while the plugin still puts the type into `onlyIn`. The group therefore
still shows up, with rows that carry no data, because the grouped field has no
selection for the addon's type, and the type is searched twice per query. To
migrate:

1. Delete the operation extension file.
2. Add the fragment from the quick search example above.
3. Remove `quickSearchResultKey` from the plugin, which keeps all its other
   fields.

## Not yet proven (honest scope)

- Only tested against the `near-operation-file` preset and the two mocker
  presets already in `.graphql_code_generator.js`; other presets were not
  exercised.
- A base document is assumed to define at most one operation (matches every
  document under `app/frontend` today, and `mocksGraphqlPlugin.js` makes the
  same assumption).
