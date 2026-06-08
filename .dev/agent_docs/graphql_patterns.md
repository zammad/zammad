# GraphQL Patterns

## Resolver Structure

Resolvers are thin wrappers. Business logic lives in `app/services/service/`:

```ruby
def resolve(...)
  Service::SomeAction.new(...).execute
end
```

## Authorization

Multiple layers, applied declaratively:

- `requires_permission('ticket.agent')` — static permission check at resolver level
- `allow_public_access!` — opt-out of authentication
- `loads_pundit_method: :update?` — authorize loaded objects via Pundit
  at argument level
- `requires_enabled_setting('some_feature')` /
  `requires_disabled_setting(...)` — feature flag guards

Object-level authorization uses Pundit via `HasPunditAuthorization`
concern on types.

## Auto-Registration

Queries, mutations, and subscriptions are auto-registered — no manual
field registration needed. Just create the class inheriting from the
appropriate base and it will be discovered.

## Custom Relation DSL

Types use custom macros (not standard graphql-ruby):

```ruby
belongs_to :group, Gql::Types::GroupType
has_one :organization, Gql::Types::OrganizationType
```

These automatically set up batch-loaded resolvers and mark fields as
dependent for permission checks.

## Scoped Fields

```ruby
scoped_fields do
  field :some_field, String, null: true
end
```

Fields inside `scoped_fields` are restricted by Pundit FieldScope —
they return `nil` instead of errors when unauthorized. Must be nullable.

## Internal Fields

```ruby
internal_fields do
  field :some_field, String
end
```

Fields inside `internal_fields` are restricted by checking for admin/agent permission.
They return `nil` instead of errors when unauthorized.
