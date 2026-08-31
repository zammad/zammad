# Service and GraphQL Specs

How to split spec coverage between a service and the query, mutation or
subscription that calls it. For everything else about tests see
`.dev/agent_docs/testing.md`.

When a query, mutation or subscription delegates to a service, test each
layer once. Write the service spec first.

Service spec (`spec/services/service/...`) — everything the service
decides:

- what it writes, and what it leaves alone
- failures, as the raised exception, plus the rollback
- authorization it performs itself, and `requires_current_user!`
- every form its arguments accept (a record as well as an id or code)

GraphQL spec (`spec/graphql/gql/{queries,mutations,subscriptions}/...`) —
only what the GraphQL layer adds:

- schema-level rejections: missing or blank arguments, custom scalars
- declarative authorization: `requires_permission`,
  `loads_pundit_method:`, and the shared example
  `graphql responds with error if unauthenticated`
- how a service error reaches the client: user error with `message` and
  `field`, or a top-level error
- the payload: which fields come back, in which locale
- fields the types resolve themselves (batch loaders, connections,
  pagination) and their query-count tests

Do not repeat the service's matrix (roles, locales, permissions, tree
shapes) in the GraphQL spec. One loose example that an argument reaches
the service is enough. Name the service spec in a comment at the top.

Example: `spec/services/service/knowledge_base/category/create_spec.rb`
and `spec/graphql/gql/mutations/knowledge_base/category/add_spec.rb`.
