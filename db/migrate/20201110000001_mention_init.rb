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
    update_user_matrix
  end

  def create_overview
    Overview.create_if_not_exists(
      name:          'My mentioned Tickets',
      link:          'my_mentioned_tickets',
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

  def update_user_matrix
    User.with_permissions('ticket.agent').each do |user|
      next if user.preferences.blank?
      next if user.preferences['notification_config'].blank?
      next if user.preferences['notification_config']['matrix'].blank?

      update_user_matrix_by_user(user)
    end
  end

  def update_user_matrix_by_user(user)
    %w[create update].each do |type|
      user.preferences['notification_config']['matrix'][type]['criteria']['mentioned'] = true
    end

    %w[reminder_reached escalation].each do |type|
      user.preferences['notification_config']['matrix'][type]['criteria']['mentioned'] = false
    end
    user.save!
  end
end
