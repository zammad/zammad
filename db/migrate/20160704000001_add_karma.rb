class AddKarma < ActiveRecord::Migration
  def up

    create_table :karma_users do |t|
      t.integer :user_id,                           null: false
      t.integer :score,                             null: false
      t.string  :level,               limit: 200,   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_users, [:user_id], unique: true

    create_table :karma_activities do |t|
      t.string  :name,                limit: 200,    null: false
      t.string  :description,         limit: 200,    null: false
      t.integer :score,                              null: false
      t.integer :once_ttl,                           null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_activities, [:name], unique: true
    Karma::Activity.create_or_update(
      name: 'ticket create',
      description: 'You have created a ticket',
      score: 10,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket close',
      description: 'You have closed a ticket',
      score: 5,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket answer 1h',
      description: 'You have answered a ticket within 1h',
      score: 25,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket answer 2h',
      description: 'You have answered a ticket within 2h',
      score: 20,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket answer 12h',
      description: 'You have answered a ticket within 12h',
      score: 10,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket answer 24h',
      description: 'You have answered a ticket within 24h',
      score: 5,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket pending state',
      description: 'Usage of advanced features',
      score: 2,
      once_ttl: 60,
    )
    Karma::Activity.create_or_update(
      name: 'ticket escalated',
      description: 'You have escalated tickets',
      score: -5,
      once_ttl: 60 * 60 * 24,
    )
    Karma::Activity.create_or_update(
      name: 'ticket reminder overdue (+2 days)',
      description: 'You have tickets that are over 2 days overdue',
      score: -5,
      once_ttl: 60 * 60 * 24,
    )
    Karma::Activity.create_or_update(
      name: 'text module',
      description: 'Usage of advanced features',
      score: 4,
      once_ttl: 60 * 30,
    )
    Karma::Activity.create_or_update(
      name: 'tagging',
      description: 'Usage of advanced features',
      score: 4,
      once_ttl: 60 * 60 * 4,
    )

    create_table :karma_activity_logs do |t|
      t.integer :o_id,                          null: false
      t.integer :object_lookup_id,              null: false
      t.integer :user_id,                       null: false
      t.integer :activity_id,                   null: false
      t.integer :score,                         null: false
      t.integer :score_total,                   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_activity_logs, [:user_id]
    add_index :karma_activity_logs, [:created_at]
    add_index :karma_activity_logs, [:o_id, :object_lookup_id]

    Setting.create_if_not_exists(
      title: 'Define transaction backend.',
      name: '9200_karma',
      area: 'Transaction::Backend::Async',
      description: 'Define the transaction backend which creates the karma score.',
      options: {},
      state: 'Transaction::Karma',
      frontend: false
    )

    Setting.create_if_not_exists(
      title: 'Define karma levels.',
      name: 'karma_levels',
      area: 'Core::Karma',
      description: 'Define the karma levels.',
      options: {},
      state: [
        {
          name: 'Beginner',
          start: 0,
          end: 499,
        },
        {
          name: 'Newbie',
          start: 500,
          end: 1999,
        },
        {
          name: 'Intermediate',
          start: 2000,
          end: 4999,
        },
        {
          name: 'Professional',
          start: 5000,
          end: 6999,
        },
        {
          name: 'Expert',
          start: 7000,
          end: 8999,
        },
        {
          name: 'Master',
          start: 9000,
          end: 18_999,
        },
        {
          name: 'Evangelist',
          start: 19_000,
          end: 45_999,
        },
        {
          name: 'Hero',
          start: 50_000,
          end: nil,
        },
      ],
      frontend: false
    )

  end
end
