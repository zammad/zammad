class CreateTicket < ActiveRecord::Migration[4.2]
  def up
    create_table :ticket_state_types do |t|
      t.column :name,                 :string, limit: 250, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :updated_by_id,        :integer,            null: false
      t.column :created_by_id,        :integer,            null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_state_types, [:name], unique: true
    add_foreign_key :ticket_state_types, :users, column: :created_by_id
    add_foreign_key :ticket_state_types, :users, column: :updated_by_id

    create_table :ticket_states do |t|
      t.references :state_type, null: false
      t.column :name,                 :string, limit: 250,  null: false
      t.column :next_state_id,        :integer,             null: true
      t.column :ignore_escalation,    :boolean,             null: false, default: false
      t.column :default_create,       :boolean,             null: false, default: false
      t.column :default_follow_up,    :boolean,             null: false, default: false
      t.column :note,                 :string, limit: 250,  null: true
      t.column :active,               :boolean,             null: false, default: true
      t.column :updated_by_id,        :integer,             null: false
      t.column :created_by_id,        :integer,             null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_states, [:name], unique: true
    add_index :ticket_states, [:default_create]
    add_index :ticket_states, [:default_follow_up]
    add_foreign_key :ticket_states, :ticket_state_types, column: :state_type_id
    add_foreign_key :ticket_states, :users, column: :created_by_id
    add_foreign_key :ticket_states, :users, column: :updated_by_id

    create_table :ticket_priorities do |t|
      t.column :name,                 :string, limit: 250, null: false
      t.column :default_create,       :boolean,            null: false, default: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :active,               :boolean,            null: false, default: true
      t.column :updated_by_id,        :integer,            null: false
      t.column :created_by_id,        :integer,            null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_priorities, [:name], unique: true
    add_index :ticket_priorities, [:default_create]
    add_foreign_key :ticket_priorities, :users, column: :created_by_id
    add_foreign_key :ticket_priorities, :users, column: :updated_by_id

    create_table :tickets do |t|
      t.references :group,                                                null: false
      t.references :priority,                                             null: false
      t.references :state,                                                null: false
      t.references :organization,                                         null: true
      t.column :number,                           :string,    limit: 60,  null: false
      t.column :title,                            :string,    limit: 250, null: false
      t.column :owner_id,                         :integer,               null: false
      t.column :customer_id,                      :integer,               null: false
      t.column :note,                             :string,    limit: 250, null: true
      t.column :first_response_at,                :timestamp, limit: 3,   null: true
      t.column :first_response_escalation_at,     :timestamp, limit: 3,   null: true
      t.column :first_response_in_min,            :integer,               null: true
      t.column :first_response_diff_in_min,       :integer,               null: true
      t.column :close_at,                         :timestamp, limit: 3,   null: true
      t.column :close_escalation_at,              :timestamp, limit: 3,   null: true
      t.column :close_in_min,                     :integer,               null: true
      t.column :close_diff_in_min,                :integer,               null: true
      t.column :update_escalation_at,             :timestamp, limit: 3,   null: true
      t.column :update_in_min,                    :integer,               null: true
      t.column :update_diff_in_min,               :integer,               null: true
      t.column :last_contact_at,                  :timestamp, limit: 3,   null: true
      t.column :last_contact_agent_at,            :timestamp, limit: 3,   null: true
      t.column :last_contact_customer_at,         :timestamp, limit: 3,   null: true
      t.column :last_owner_update_at,             :timestamp, limit: 3,   null: true
      t.column :create_article_type_id,           :integer,               null: true
      t.column :create_article_sender_id,         :integer,               null: true
      t.column :article_count,                    :integer,               null: true
      t.column :escalation_at,                    :timestamp, limit: 3,   null: true
      t.column :pending_time,                     :timestamp, limit: 3,   null: true
      t.column :type,                             :string,    limit: 100, null: true
      t.column :time_unit,                        :decimal, precision: 6, scale: 2, null: true
      t.column :preferences,                      :text,      limit: 500.kilobytes + 1, null: true
      t.column :updated_by_id,                    :integer,               null: false
      t.column :created_by_id,                    :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :tickets, [:state_id]
    add_index :tickets, [:priority_id]
    add_index :tickets, [:group_id]
    add_index :tickets, [:owner_id]
    add_index :tickets, [:customer_id]
    add_index :tickets, [:number], unique: true
    add_index :tickets, [:title]
    add_index :tickets, [:created_at]
    add_index :tickets, [:first_response_at]
    add_index :tickets, [:first_response_escalation_at]
    add_index :tickets, [:first_response_in_min]
    add_index :tickets, [:first_response_diff_in_min]
    add_index :tickets, [:close_at]
    add_index :tickets, [:close_escalation_at]
    add_index :tickets, [:close_in_min]
    add_index :tickets, [:close_diff_in_min]
    add_index :tickets, [:escalation_at]
    add_index :tickets, [:update_in_min]
    add_index :tickets, [:update_diff_in_min]
    add_index :tickets, [:last_contact_at]
    add_index :tickets, [:last_contact_agent_at]
    add_index :tickets, [:last_contact_customer_at]
    add_index :tickets, [:last_owner_update_at]
    add_index :tickets, [:create_article_type_id]
    add_index :tickets, [:create_article_sender_id]
    add_index :tickets, [:created_by_id]
    add_index :tickets, [:pending_time]
    add_index :tickets, [:type]
    add_index :tickets, [:time_unit]
    add_foreign_key :tickets, :groups
    add_foreign_key :tickets, :users, column: :owner_id
    add_foreign_key :tickets, :users, column: :customer_id
    add_foreign_key :tickets, :ticket_priorities, column: :priority_id
    add_foreign_key :tickets, :ticket_states, column: :state_id
    add_foreign_key :tickets, :organizations
    add_foreign_key :tickets, :users, column: :created_by_id
    add_foreign_key :tickets, :users, column: :updated_by_id

    create_table :ticket_flags do |t|
      t.references :ticket,                          null: false
      t.column :key,            :string, limit: 50,  null: false
      t.column :value,          :string, limit: 50,  null: true
      t.column :created_by_id,  :integer,            null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_flags, %i[ticket_id created_by_id]
    add_index :ticket_flags, %i[ticket_id key]
    add_index :ticket_flags, [:ticket_id]
    add_index :ticket_flags, [:created_by_id]
    add_foreign_key :ticket_flags, :tickets, column: :ticket_id
    add_foreign_key :ticket_flags, :users, column: :created_by_id

    create_table :ticket_article_types do |t|
      t.column :name,                 :string, limit: 250, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :communication,        :boolean,            null: false
      t.column :active,               :boolean,            null: false, default: true
      t.column :updated_by_id,        :integer,            null: false
      t.column :created_by_id,        :integer,            null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_article_types, [:name], unique: true
    add_foreign_key :ticket_article_types, :users, column: :created_by_id
    add_foreign_key :ticket_article_types, :users, column: :updated_by_id

    create_table :ticket_article_senders do |t|
      t.column :name,                 :string, limit: 250, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :updated_by_id,        :integer,            null: false
      t.column :created_by_id,        :integer,            null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_article_senders, [:name], unique: true
    add_foreign_key :ticket_article_senders, :users, column: :created_by_id
    add_foreign_key :ticket_article_senders, :users, column: :updated_by_id

    create_table :ticket_articles do |t|
      t.references :ticket,                                    null: false
      t.references :type,                                      null: false
      t.references :sender,                                    null: false
      t.column :from,                 :string, limit: 3000,    null: true
      t.column :to,                   :string, limit: 3000,    null: true
      t.column :cc,                   :string, limit: 3000,    null: true
      t.column :subject,              :string, limit: 3000,    null: true
      t.column :reply_to,             :string, limit: 300,     null: true
      t.column :message_id,           :string, limit: 3000,    null: true
      t.column :message_id_md5,       :string, limit: 32,      null: true
      t.column :in_reply_to,          :string, limit: 3000,    null: true
      t.column :content_type,         :string, limit: 20,      null: false, default: 'text/plain'
      t.column :references,           :string, limit: 3200,    null: true
      t.column :body,                 :text,   limit: 20.megabytes + 1, null: false
      t.column :internal,             :boolean,                null: false, default: false
      t.column :preferences,          :text,   limit: 500.kilobytes + 1, null: true
      t.column :updated_by_id,        :integer,                null: false
      t.column :created_by_id,        :integer,                null: false
      t.column :origin_by_id,         :integer
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_articles, [:ticket_id]
    add_index :ticket_articles, [:message_id_md5]
    add_index :ticket_articles, %i[message_id_md5 type_id], name: 'index_ticket_articles_message_id_md5_type_id'
    add_index :ticket_articles, [:created_by_id]
    add_index :ticket_articles, [:created_at]
    add_index :ticket_articles, [:internal]
    add_index :ticket_articles, [:type_id]
    add_index :ticket_articles, [:sender_id]
    add_foreign_key :ticket_articles, :tickets
    add_foreign_key :ticket_articles, :ticket_article_types, column: :type_id
    add_foreign_key :ticket_articles, :ticket_article_senders, column: :sender_id
    add_foreign_key :ticket_articles, :users, column: :created_by_id
    add_foreign_key :ticket_articles, :users, column: :updated_by_id
    add_foreign_key :ticket_articles, :users, column: :origin_by_id

    create_table :ticket_article_flags do |t|
      t.references :ticket_article,                      null: false
      t.column :key,                 :string, limit: 50, null: false
      t.column :value,               :string, limit: 50, null: true
      t.column :created_by_id,       :integer,           null: false
      t.timestamps limit: 3,  null: false
    end
    add_index :ticket_article_flags, %i[ticket_article_id created_by_id], name: 'index_ticket_article_flags_on_articles_id_and_created_by_id'
    add_index :ticket_article_flags, %i[ticket_article_id key]
    add_index :ticket_article_flags, [:ticket_article_id]
    add_index :ticket_article_flags, [:created_by_id]
    add_foreign_key :ticket_article_flags, :ticket_articles, column: :ticket_article_id
    add_foreign_key :ticket_article_flags, :users, column: :created_by_id

    create_table :ticket_time_accountings do |t|
      t.references :ticket,                                       null: false
      t.references :ticket_article,                               null: true
      t.column :time_unit,      :decimal, precision: 6, scale: 2, null: false
      t.column :created_by_id,  :integer,                         null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_time_accountings, [:ticket_id]
    add_index :ticket_time_accountings, [:ticket_article_id]
    add_index :ticket_time_accountings, [:created_by_id]
    add_index :ticket_time_accountings, [:time_unit]
    add_foreign_key :ticket_time_accountings, :tickets
    add_foreign_key :ticket_time_accountings, :ticket_articles
    add_foreign_key :ticket_time_accountings, :users, column: :created_by_id

    create_table :ticket_counters do |t|
      t.column :content,              :string, limit: 100, null: false
      t.column :generator,            :string, limit: 100, null: false
    end
    add_index :ticket_counters, [:generator], unique: true

    create_table :overviews do |t|
      t.column :name,                 :string,  limit: 250,    null: false
      t.column :link,                 :string,  limit: 250,    null: false
      t.column :prio,                 :integer,                null: false
      t.column :condition,            :text, limit: 500.kilobytes + 1, null: false
      t.column :order,                :string,  limit: 2500,   null: false
      t.column :group_by,             :string,  limit: 250,    null: true
      t.column :group_direction,      :string,  limit: 250,    null: true
      t.column :organization_shared,  :boolean,                null: false, default: false
      t.column :out_of_office,        :boolean,                null: false, default: false
      t.column :view,                 :string,  limit: 1000,   null: false
      t.column :active,               :boolean,                null: false, default: true
      t.column :updated_by_id,        :integer,                null: false
      t.column :created_by_id,        :integer,                null: false
      t.timestamps limit: 3, null: false
    end
    add_index :overviews, [:name]
    add_foreign_key :overviews, :users, column: :created_by_id
    add_foreign_key :overviews, :users, column: :updated_by_id

    create_table :overviews_roles, id: false do |t|
      t.references :overview
      t.references :role
    end
    add_index :overviews_roles, [:overview_id]
    add_index :overviews_roles, [:role_id]
    add_foreign_key :overviews_roles, :overviews
    add_foreign_key :overviews_roles, :roles

    create_table :overviews_users, id: false do |t|
      t.references :overview
      t.references :user
    end
    add_index :overviews_users, [:overview_id]
    add_index :overviews_users, [:user_id]
    add_foreign_key :overviews_users, :overviews
    add_foreign_key :overviews_users, :users

    create_table :overviews_groups, id: false do |t|
      t.references :overview
      t.references :group
    end
    add_index :overviews_groups, [:overview_id]
    add_index :overviews_groups, [:group_id]
    add_foreign_key :overviews_groups, :overviews
    add_foreign_key :overviews_groups, :groups

    create_table :triggers do |t|
      t.column :name,                 :string, limit: 250,    null: false
      t.column :condition,            :text, limit: 500.kilobytes + 1, null: false
      t.column :perform,              :text, limit: 500.kilobytes + 1, null: false
      t.column :disable_notification, :boolean,               null: false, default: true
      t.column :note,                 :string, limit: 250,    null: true
      t.column :active,               :boolean,               null: false, default: true
      t.column :updated_by_id,        :integer,               null: false
      t.column :created_by_id,        :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :triggers, [:name], unique: true
    add_foreign_key :triggers, :users, column: :created_by_id
    add_foreign_key :triggers, :users, column: :updated_by_id

    create_table :jobs do |t|
      t.column :name,                 :string,  limit: 250,    null: false
      t.column :timeplan,             :string,  limit: 2500,   null: false
      t.column :condition,            :text, limit: 500.kilobytes + 1, null: false
      t.column :perform,              :text, limit: 500.kilobytes + 1, null: false
      t.column :disable_notification, :boolean,                null: false, default: true
      t.column :last_run_at,          :timestamp, limit: 3,    null: true
      t.column :next_run_at,          :timestamp, limit: 3,    null: true
      t.column :running,              :boolean,                null: false, default: false
      t.column :processed,            :integer,                null: false, default: 0
      t.column :matching,             :integer,                null: false
      t.column :pid,                  :string,  limit: 250,    null: true
      t.column :note,                 :string,  limit: 250,    null: true
      t.column :active,               :boolean,                null: false, default: false
      t.column :updated_by_id,        :integer,                null: false
      t.column :created_by_id,        :integer,                null: false
      t.timestamps limit: 3, null: false
    end
    add_index :jobs, [:name], unique: true
    add_foreign_key :jobs, :users, column: :created_by_id
    add_foreign_key :jobs, :users, column: :updated_by_id

    create_table :notifications do |t|
      t.column :subject,      :string, limit: 250,   null: false
      t.column :body,         :string, limit: 8000,  null: false
      t.column :content_type, :string, limit: 250,   null: false
      t.column :active,       :boolean,              null: false, default: true
      t.column :note,         :string, limit: 250,   null: true
      t.timestamps limit: 3, null: false
    end

    create_table :link_types do |t|
      t.column :name,         :string, limit: 250,   null: false
      t.column :note,         :string, limit: 250,   null: true
      t.column :active,       :boolean,              null: false, default: true
      t.timestamps limit: 3, null: false
    end
    add_index :link_types, [:name], unique: true

    create_table :link_objects do |t|
      t.column :name,         :string, limit: 250,   null: false
      t.column :note,         :string, limit: 250,   null: true
      t.column :active,       :boolean,              null: false, default: true
      t.timestamps limit: 3, null: false
    end
    add_index :link_objects, [:name],   unique: true

    create_table :links do |t|
      t.references :link_type,                            null: false
      t.column :link_object_source_id,        :integer,   null: false
      t.column :link_object_source_value,     :integer,   null: false
      t.column :link_object_target_id,        :integer,   null: false
      t.column :link_object_target_value,     :integer,   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :links, %i[link_object_source_id link_object_source_value link_object_target_id link_object_target_value link_type_id], unique: true, name: 'links_uniq_total'
    add_foreign_key :links, :link_types

    create_table :postmaster_filters do |t|
      t.column :name,           :string, limit: 250,    null: false
      t.column :channel,        :string, limit: 250,    null: false
      t.column :match,          :text, limit: 500.kilobytes + 1, null: false
      t.column :perform,        :text, limit: 500.kilobytes + 1, null: false
      t.column :active,         :boolean,               null: false, default: true
      t.column :note,           :string, limit: 250,    null: true
      t.column :updated_by_id,  :integer,               null: false
      t.column :created_by_id,  :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :postmaster_filters, [:channel]
    add_foreign_key :postmaster_filters, :users, column: :created_by_id
    add_foreign_key :postmaster_filters, :users, column: :updated_by_id

    create_table :text_modules do |t|
      t.references :user,                                    null: true
      t.column :name,                 :string,  limit: 250,  null: false
      t.column :keywords,             :string,  limit: 500,  null: true
      t.column :content,              :text,    limit: 10.megabytes + 1, null: false
      t.column :note,                 :string,  limit: 250,  null: true
      t.column :active,               :boolean,              null: false, default: true
      t.column :foreign_id,           :integer,              null: true
      t.column :updated_by_id,        :integer,              null: false
      t.column :created_by_id,        :integer,              null: false
      t.timestamps limit: 3, null: false
    end
    add_index :text_modules, [:user_id]
    add_index :text_modules, [:name]
    add_foreign_key :text_modules, :users
    add_foreign_key :text_modules, :users, column: :created_by_id
    add_foreign_key :text_modules, :users, column: :updated_by_id

    create_table :text_modules_groups, id: false do |t|
      t.references :text_module
      t.references :group
    end
    add_index :text_modules_groups, [:text_module_id]
    add_index :text_modules_groups, [:group_id]
    add_foreign_key :text_modules_groups, :text_modules
    add_foreign_key :text_modules_groups, :groups

    create_table :templates do |t|
      t.references :user,                                    null: true
      t.column :name,                 :string,  limit: 250,  null: false
      t.column :options,              :text,    limit: 10.megabytes + 1, null: false
      t.column :updated_by_id,        :integer,              null: false
      t.column :created_by_id,        :integer,              null: false
      t.timestamps limit: 3, null: false
    end
    add_index :templates, [:user_id]
    add_index :templates, [:name]
    add_foreign_key :templates, :users
    add_foreign_key :templates, :users, column: :created_by_id
    add_foreign_key :templates, :users, column: :updated_by_id

    create_table :templates_groups, id: false do |t|
      t.references :template
      t.references :group
    end
    add_index :templates_groups, [:template_id]
    add_index :templates_groups, [:group_id]
    add_foreign_key :templates_groups, :templates
    add_foreign_key :templates_groups, :groups

    create_table :channels do |t|
      t.references :group,                             null: true
      t.column :area,           :string, limit: 100,   null: false
      t.column :options,        :text,   limit: 500.kilobytes + 1,  null: true
      t.column :active,         :boolean,              null: false, default: true
      t.column :preferences,    :string, limit: 2000,  null: true
      t.column :last_log_in,    :text,   limit: 500.kilobytes + 1, null: true
      t.column :last_log_out,   :text,   limit: 500.kilobytes + 1, null: true
      t.column :status_in,      :string, limit: 100,   null: true
      t.column :status_out,     :string, limit: 100,   null: true
      t.column :updated_by_id,  :integer,              null: false
      t.column :created_by_id,  :integer,              null: false
      t.timestamps limit: 3, null: false
    end
    add_index :channels, [:area]
    add_foreign_key :channels, :groups
    add_foreign_key :channels, :users, column: :created_by_id
    add_foreign_key :channels, :users, column: :updated_by_id

    create_table :slas do |t|
      t.references :calendar,                                   null: false
      t.column :name,                 :string, limit: 150,      null: true
      t.column :first_response_time,  :integer,                 null: true
      t.column :update_time,          :integer,                 null: true
      t.column :solution_time,        :integer,                 null: true
      t.column :condition,            :text, limit: 500.kilobytes + 1, null: true
      t.column :updated_by_id,        :integer,                 null: false
      t.column :created_by_id,        :integer,                 null: false
      t.timestamps limit: 3, null: false
    end
    add_index :slas, [:name], unique: true
    add_foreign_key :slas, :users, column: :created_by_id
    add_foreign_key :slas, :users, column: :updated_by_id

    create_table :macros do |t|
      t.string  :name,                   limit: 250,    null: true
      t.text    :perform,                limit: 500.kilobytes + 1, null: false
      t.boolean :active,                                null: false, default: true
      t.string  :ux_flow_next_up,                       null: false, default: 'none'
      t.string  :note,                   limit: 250,    null: true
      t.integer :updated_by_id,                         null: false
      t.integer :created_by_id,                         null: false
      t.timestamps limit: 3, null: false
    end
    add_index :macros, [:name], unique: true
    add_foreign_key :macros, :users, column: :created_by_id
    add_foreign_key :macros, :users, column: :updated_by_id

    create_table :chats do |t|
      t.string  :name,                   limit: 250,  null: true
      t.integer :max_queue,                           null: false, default: 5
      t.string  :note,                   limit: 250,  null: true
      t.boolean :active,                              null: false, default: true
      t.boolean :public,                              null: false, default: false
      t.string  :block_ip,               limit: 5000, null: true
      t.string  :block_country,          limit: 5000, null: true
      t.string  :preferences,            limit: 5000, null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps limit: 3, null: false
    end
    add_index :chats, [:name], unique: true
    add_foreign_key :chats, :users, column: :created_by_id
    add_foreign_key :chats, :users, column: :updated_by_id

    create_table :chat_topics do |t|
      t.integer :chat_id,                             null: false
      t.string  :name,                   limit: 250,  null: false
      t.string  :note,                   limit: 250,  null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps limit: 3, null: false
    end
    add_index :chat_topics, [:name], unique: true
    add_foreign_key :chat_topics, :users, column: :created_by_id
    add_foreign_key :chat_topics, :users, column: :updated_by_id

    create_table :chat_sessions do |t|
      t.references :chat,                             null: false
      t.string  :session_id,                          null: false
      t.string  :name,                   limit: 250,  null: true
      t.string  :state,                  limit:  50,  null: false, default: 'waiting' # running, closed
      t.references :user,                             null: true
      t.text    :preferences,            limit: 100.kilobytes + 1, null: true
      t.integer :updated_by_id,                       null: true
      t.integer :created_by_id,                       null: true
      t.timestamps limit: 3, null: false
    end
    add_index :chat_sessions, [:session_id]
    add_index :chat_sessions, [:state]
    add_index :chat_sessions, [:user_id]
    add_index :chat_sessions, [:chat_id]
    add_foreign_key :chat_sessions, :chats
    add_foreign_key :chat_sessions, :users
    add_foreign_key :chat_sessions, :users, column: :created_by_id
    add_foreign_key :chat_sessions, :users, column: :updated_by_id

    create_table :chat_messages do |t|
      t.references :chat_session,                     null: false
      t.text    :content,    limit: 20.megabytes + 1, null: false
      t.integer :created_by_id,                       null: true
      t.timestamps limit: 3, null: false
    end
    add_index :chat_messages, [:chat_session_id]
    add_foreign_key :chat_messages, :chat_sessions
    add_foreign_key :chat_messages, :users, column: :created_by_id

    create_table :chat_agents do |t|
      t.boolean :active,                              null: false, default: true
      t.integer :concurrent,                          null: false, default: 5
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps limit: 3, null: false
    end
    add_index :chat_agents, [:active]
    add_index :chat_agents, [:updated_by_id], unique: true
    add_index :chat_agents, [:created_by_id], unique: true
    add_foreign_key :chat_agents, :users, column: :created_by_id
    add_foreign_key :chat_agents, :users, column: :updated_by_id

    create_table :report_profiles do |t|
      t.column :name,           :string, limit: 150,    null: true
      t.column :condition,      :text, limit: 500.kilobytes + 1, null: true
      t.column :active,         :boolean,               null: false, default: true
      t.column :updated_by_id,  :integer,               null: false
      t.column :created_by_id,  :integer,               null: false
      t.timestamps limit: 3, null: false
    end
    add_index :report_profiles, [:name], unique: true
    add_foreign_key :report_profiles, :users, column: :created_by_id
    add_foreign_key :report_profiles, :users, column: :updated_by_id

    create_table :karma_users do |t|
      t.references :user,                           null: false
      t.integer :score,                             null: false
      t.string  :level,               limit: 200,   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_users, [:user_id], unique: true
    add_foreign_key :karma_users, :users

    create_table :karma_activities do |t|
      t.string  :name,                limit: 200,    null: false
      t.string  :description,         limit: 200,    null: false
      t.integer :score,                              null: false
      t.integer :once_ttl,                           null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_activities, [:name], unique: true

    create_table :karma_activity_logs do |t|
      t.integer :o_id,                          null: false
      t.integer :object_lookup_id,              null: false
      t.references :user,                       null: false
      t.integer :activity_id,                   null: false
      t.integer :score,                         null: false
      t.integer :score_total,                   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :karma_activity_logs, [:user_id]
    add_index :karma_activity_logs, [:created_at]
    add_index :karma_activity_logs, %i[o_id object_lookup_id]
    add_foreign_key :karma_activity_logs, :users
    add_foreign_key :karma_activity_logs, :karma_activities, column: :activity_id
  end

  def self.down
    drop_table :karma_activity_logs
    drop_table :karma_activities
    drop_table :karma_users
    drop_table :report_profiles
    drop_table :chat_topics
    drop_table :chat_sessions
    drop_table :chat_messages
    drop_table :chat_agents
    drop_table :chats
    drop_table :macros
    drop_table :slas
    drop_table :channels
    drop_table :templates_groups
    drop_table :templates
    drop_table :text_modules_groups
    drop_table :text_modules
    drop_table :postmaster_filters
    drop_table :notifications
    drop_table :triggers
    drop_table :links
    drop_table :link_types
    drop_table :link_objects
    drop_table :overviews
    drop_table :ticket_counters
    drop_table :ticket_time_accounting
    drop_table :ticket_article_flags
    drop_table :ticket_articles
    drop_table :ticket_article_types
    drop_table :ticket_article_senders
    drop_table :ticket_flags
    drop_table :tickets
    drop_table :ticket_priorities
    drop_table :ticket_states
    drop_table :ticket_state_types
  end
end
