# Database Migrations & Seeds

## Creating a Migration

```bash
rails generate migration IssueNumberShortDescription
```

The generator template automatically includes the `system_init_done` guard
(`return if !Setting.exists?(name: 'system_init_done')`), which skips
data-migration logic on fresh installations where seeds handle setup.
Zammad migrations can include data migrations, not just schema changes.

- Call `Model.reset_column_information` after adding/removing columns
  in the same migration

## Schema Changes

When modifying table structure, also update the base migrations
so fresh installations get the same schema (migrations are cumulative,
but base files are the canonical schema source for new installs):

- `db/migrate/20120101000001_create_base.rb`
- `db/migrate/20120101000010_create_ticket.rb`

Conventions:

- Use `limit: 3` for timestamp precision
- Specify `type: :integer` for polymorphic references
- Use `id: :integer` in `create_table` calls (Zammad uses integer primary keys, not bigint)
- Add indexes for frequently queried columns

## Settings

New or updated settings must be added in both the migration and the seeds.
See existing examples in `db/seeds/settings.rb` for the correct structure.

## Seeds

Seeds live in `db/seeds/` and use idempotent methods like
`create_if_not_exists` to avoid duplicates. When adding user-facing fields,
also update `db/seeds/object_manager_attributes.rb`.

## Helpers

`MigrationHelper` (`lib/migration_helper.rb`) provides utilities for
renaming custom object attributes and handling reserved SQL words.

## Testing

```bash
rake db:migrate              # Test the migration
rake db:rollback STEP=1      # Undo last migration (schema only — data migrations are not reversed)
```
