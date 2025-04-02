# How to Add a Database Migration

## 1. Use Rails generator

Please provide a migration name (no spacings, special characters) like in the example below.

```screen
rails generate migration Issue1337IssueDescription
    invoke  active_record
    create    db/migrate/20220715094714_issue1337_issue_description.rb
```

## 2. Apply Zammad patch

Zammad's custom seeding/migration handling require a piece of code
to be added to the start of all new migrations.

```ruby
# return if it's a new setup
return if !Setting.exists?(name: 'system_init_done')
```

## 3. Add the actual migration content

Your initial migration file now should like so:

```ruby
class Issue1337IssueDescription < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    #
    # custom migration content
    #
  end
end
```

## 4. Adjust seeds file or base migrations

Now that existing Zammad installations are updated with your settings or database changes,
you'll also have to ensure this happens to newly created, seeding installations.

If your migration contains database schema changes, these need to be reflected in the base schema
migrations [create_base](/db/migrate/20120101000001_create_base.rb) and
[create_ticket](/db/migrate/20120101000010_create_ticket.rb). These migrations create the full schema on new systems.

Any changes that involve database content must be applied in the corresponding [file in db/seeds/](/db/seeds/).

## 5. Testing

Now you're ready to test the migration (`rake db:migrate`) and installation/seeding (`rake zammad:db:reset`).

If your newly created migration is not running fine, don't be worried. You could simply do a rollback via
`rake db:rollback STEP=1` and re-run the migration.
