# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MentionInit < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_table :mentions do |t|
      t.references :mentionable,      polymorphic: true, null: false
      t.column :user_id,              :integer, null: false
      t.column :updated_by_id,        :integer, null: false
      t.column :created_by_id,        :integer, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :mentions, %i[mentionable_id mentionable_type user_id], unique: true, name: 'index_mentions_mentionable_user'
    add_foreign_key :mentions, :users, column: :created_by_id
    add_foreign_key :mentions, :users, column: :updated_by_id
    add_foreign_key :mentions, :users, column: :user_id

    Mention.reset_column_information
    create_overview
    update_users
  end

  def create_overview
    Overview.create_if_not_exists(
      name:          'My subscribed Tickets',
      link:          'my_subscribed_tickets',
      prio:          1025,
      role_ids:      Role.with_permissions('ticket.agent').pluck(:id),
      condition:     { 'ticket.mention_user_ids'=>{ 'operator' => 'is', 'pre_condition' => 'current_user.id', 'value' => '', 'value_completion' => '' } },
      order:         {
        by:        'created_at',
        direction: 'ASC',
      },
      view:          {
        d:                 %w[title customer group created_at],
        s:                 %w[title customer group created_at],
        m:                 %w[number title customer group created_at],
        view_mode_default: 's',
      },
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  def update_users
    User.with_permissions('ticket.agent').each do |user|
      next if user.preferences.blank?
      next if user.preferences['notification_config'].blank?
      next if user.preferences['notification_config']['matrix'].blank?

      update_matrix(user.preferences['notification_config']['matrix'])

      user.save!
    end
  end

  def update_matrix(matrix)
    matrix_type_defaults.each do |type, default|
      matrix[type] ||= {}
      matrix[type]['criteria'] ||= {}
      matrix[type]['criteria']['subscribed'] = default
    end
  end

  def matrix_type_defaults
    @matrix_type_defaults ||= {
      'create'           => true,
      'update'           => true,
      'reminder_reached' => false,
      'escalation'       => false,
    }
  end
end
