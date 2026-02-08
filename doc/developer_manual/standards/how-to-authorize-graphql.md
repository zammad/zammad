# How to Authorize GraphQL Operations

GraphQL operations (queries, mutations and subscriptions) must validate various parameters to ensure users cannot
perform unauthorized actions. Most common scenarios are covered by built-in helpers.

## Allow Public Access

By default, all operations are accessible to logged-in users, but occasionally unauthenticated sessions need access as well.

```ruby
class Query
  allow_public_access!
end
```

## Check User Permissions

This is a simple check of the current user’s permissions. It supports multiple permissions using OR logic. As well as a
plus-style syntax for AND checks.

```ruby
class Query
  requires_permission 'ticket.agent', 'ticket.customer+something'
end
```

## Require a Setting

Some features require a specific `Setting` to be enabled or, in some cases, explicitly disabled. These two helpers
handle both scenarios and also support custom error messages.

```ruby
class Mutation
  requires_enabled_setting 'checklist', error_message: __('Custom Error')
  requires_disabled_setting 'blocker'
end
```

## Use the Pundit, Developer

In many cases, a clever usage of Pundit policies may be the cleanest approach!

For example, we want to check wether a user is allowed to add a new item to the checklist. At first glance, we might
manually call `ChecklistItemPolicy#create?`. However, we can instead rely on checklist's own policy when loading the
object. If the user is allowed to update the checklist, adding a new item is implicitly permitted. In practice, we are
already checking whether the user can show? the checklist anyway.

```ruby
class AddChecklistItem < Mutation
  argument :checklist_id, loads: Gql::Types::ChecklistType, loads_pundit_method: :update?

  def resolve(checklist:)
    add_item
  end
end
```

## Neither of Above Matches My Use Case

Sometimes a special case arises where none of the above helpers are sufficient. In such cases, override the **instance**
method `def authorized?`.

- Return `true` if check passes.
- If the check fails, you have two options:
  - Return `false`.
  - Raise `Exceptions::Forbidden` with a custom error message.

Please **do not override** `self.authorized?` class method! Nor the old `self.authorize`!

No need to use `super`! Out-of-box implementation simply returns `true`.

```ruby
class Query
  argument :some_arg

  def authorized?(some_arg:)
    super_duper_custom_logic
  end
end
```

## Disable CSRF Check

This is not exactly authorization, but it's somewhat related. Usually CSRF is required to prevent cross-site
forgery attacks. However, sometimes there're legit reasons to allow any POST request.

Applies to mutations only!

```ruby
class Mutation
  skip_csrf_verification!
end
```
