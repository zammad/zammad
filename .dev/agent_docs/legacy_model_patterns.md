# Model Patterns for the Legacy CoffeeScript Stack

When introducing a new model that is used by the legacy stack (e.g. a generic
admin interface), two concerns are needed so the frontend can render and stay
in sync: REST assets and client notifications.

## REST Assets

### What assets are

REST responses for the legacy stack ship related records ("assets") alongside the
requested objects, so the frontend Spine store can render relations without extra
requests. `ApplicationModel::CanAssets` provides the default `assets(data)`
implementation; models only need their own `Model::Assets` concern when the default
is not enough.

### When to add a custom assets concern

- The model has `belongs_to` relations whose records the UI needs to render
  (e.g. a user reference or a polymorphic relation).
- The model needs to filter attributes or restrict visibility per user
  (see `app/models/group/assets.rb` — `filter_unauthorized_attributes` /
  `authorized_asset?`).

### Rules

- Only follow one-to-one (`belongs_to`) relations. NEVER include one-to-many
  relations — e.g. organization members can be a million records; shipping them
  as assets must be prevented (`app/models/organization/assets.rb` limits this).
- Guard against `nil` relations: optional `belongs_to` and polymorphic targets
  whose record has been deleted return `nil`.
- Keep the dedup guard (`return data if data[app_model][id]`) — it prevents
  infinite loops between mutually referencing assets.
- Include the concern in the model: `include Model::Assets` (after the generic
  concerns block).

### Skeleton

Minimal concern following `app/models/mention/assets.rb` and
`app/models/audit_log/assets.rb` (belongs_to user + polymorphic relation):

```ruby
class MyModel
  module Assets
    extend ActiveSupport::Concern

    def assets(data)
      app_model = self.class.to_app_model

      data[ app_model ] ||= {}
      return data if data[ app_model ][ id ]

      data[ app_model ][ id ] = attributes_with_association_ids

      if my_polymorphic_relation.present?
        data = my_polymorphic_relation.assets(data)
      end

      return data if user.blank?

      user.assets(data)
    end
  end
end
```

### Reference examples

- `app/models/mention/assets.rb` — user + polymorphic `mentionable`
- `app/models/audit_log/assets.rb` — optional user + polymorphic `auditable`
- `app/models/online_notification/assets.rb` — lookup tables + created/updated by
- `app/models/group/assets.rb` — attribute filtering and per-user authorization

## Client Notifications

Models rendered by the legacy stack (admin interfaces, collections) must
broadcast changes to connected clients, otherwise open sessions show stale
lists until a manual reload:

```ruby
class MyModel < ApplicationModel
  include ChecksClientNotification
end
```

- `app/models/concerns/checks_client_notification.rb` pushes
  `MyModel:create/update/touch/destroy` events (id + updated_at) via
  `PushMessages`; the frontend Spine collections then refetch.
- Default recipient type is `authenticated` (all logged-in clients); actual
  record access is still enforced on fetch by the controller policy.
- Restrict recipients with `client_notification_send_to :user_id` (only the
  referenced user) or skip events with
  `client_notification_events_ignored :touch, ...`.
