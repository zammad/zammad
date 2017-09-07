class ForeignKeys < ActiveRecord::Migration
  disable_ddl_transaction!

  def change

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    # remove wrong plural of ID columns
    ActiveRecord::Migration.rename_column :ticket_flags, :tickets_id, :ticket_id
    ActiveRecord::Migration.rename_column :ticket_article_flags, :ticket_articles_id, :ticket_article_id

    # add missing foreign keys
    foreign_keys = [
      # Base
      [:users, :organizations],
      [:users, :users, column: :created_by_id],
      [:users, :users, column: :updated_by_id],

      [:signatures, :users, column: :created_by_id],
      [:signatures, :users, column: :updated_by_id],

      [:email_addresses, :users, column: :created_by_id],
      [:email_addresses, :users, column: :updated_by_id],

      [:groups, :signatures],
      [:groups, :email_addresses],
      [:groups, :users, column: :created_by_id],
      [:groups, :users, column: :updated_by_id],

      [:roles, :users, column: :created_by_id],
      [:roles, :users, column: :updated_by_id],

      [:organizations, :users, column: :created_by_id],
      [:organizations, :users, column: :updated_by_id],

      [:roles_users, :users],
      [:roles_users, :roles],

      [:groups_users, :users],
      [:groups_users, :groups],

      [:organizations_users, :users],
      [:organizations_users, :organizations],

      [:authorizations, :users],

      [:translations, :users, column: :created_by_id],
      [:translations, :users, column: :updated_by_id],

      [:tokens, :users],

      [:packages, :users, column: :created_by_id],
      [:packages, :users, column: :updated_by_id],

      [:taskbars, :users],

      [:tags, :tag_items],
      [:tags, :tag_objects],
      [:tags, :users, column: :created_by_id],

      [:recent_views, :object_lookups, column: :recent_view_object_id],
      [:recent_views, :users, column: :created_by_id],

      [:activity_streams, :type_lookups, column: :activity_stream_type_id],
      [:activity_streams, :object_lookups, column: :activity_stream_object_id],
      [:activity_streams, :permissions],
      [:activity_streams, :groups],
      [:activity_streams, :users, column: :created_by_id],

      [:histories, :history_types],
      [:histories, :history_objects],
      [:histories, :history_attributes],
      [:histories, :users, column: :created_by_id],

      [:stores, :store_objects],
      [:stores, :store_files],
      [:stores, :users, column: :created_by_id],

      [:avatars, :users, column: :created_by_id],
      [:avatars, :users, column: :updated_by_id],

      [:online_notifications, :users, column: :created_by_id],
      [:online_notifications, :users, column: :updated_by_id],

      [:schedulers, :users, column: :created_by_id],
      [:schedulers, :users, column: :updated_by_id],

      [:calendars, :users, column: :created_by_id],
      [:calendars, :users, column: :updated_by_id],

      [:user_devices, :users],

      [:object_manager_attributes, :object_lookups],
      [:object_manager_attributes, :users, column: :created_by_id],
      [:object_manager_attributes, :users, column: :updated_by_id],

      [:cti_caller_ids, :users],

      [:stats_stores, :users, column: :created_by_id],

      [:http_logs, :users, column: :created_by_id],
      [:http_logs, :users, column: :updated_by_id],

      # Ticket
      [:ticket_state_types, :users, column: :created_by_id],
      [:ticket_state_types, :users, column: :updated_by_id],

      [:ticket_states, :ticket_state_types, column: :state_type_id],
      [:ticket_states, :users, column: :created_by_id],
      [:ticket_states, :users, column: :updated_by_id],

      [:ticket_priorities, :users, column: :created_by_id],
      [:ticket_priorities, :users, column: :updated_by_id],

      [:tickets, :groups],
      [:tickets, :users, column: :owner_id],
      [:tickets, :users, column: :customer_id],
      [:tickets, :ticket_priorities, column: :priority_id],
      [:tickets, :ticket_states, column: :state_id],
      [:tickets, :organizations],
      [:tickets, :users, column: :created_by_id],
      [:tickets, :users, column: :updated_by_id],

      [:ticket_flags, :tickets, column: :ticket_id],
      [:ticket_flags, :users, column: :created_by_id],

      [:ticket_article_types, :users, column: :created_by_id],
      [:ticket_article_types, :users, column: :updated_by_id],

      [:ticket_article_senders, :users, column: :created_by_id],
      [:ticket_article_senders, :users, column: :updated_by_id],

      [:ticket_articles, :tickets],
      [:ticket_articles, :ticket_article_types, column: :type_id],
      [:ticket_articles, :ticket_article_senders, column: :sender_id],
      [:ticket_articles, :users, column: :created_by_id],
      [:ticket_articles, :users, column: :updated_by_id],
      [:ticket_articles, :users, column: :origin_by_id],

      [:ticket_article_flags, :ticket_articles, column: :ticket_article_id],
      [:ticket_article_flags, :users, column: :created_by_id],

      [:ticket_time_accountings, :tickets],
      [:ticket_time_accountings, :ticket_articles],
      [:ticket_time_accountings, :users, column: :created_by_id],

      [:overviews, :users, column: :created_by_id],
      [:overviews, :users, column: :updated_by_id],

      [:overviews_roles, :overviews],
      [:overviews_roles, :roles],

      [:overviews_users, :overviews],
      [:overviews_users, :users],

      [:overviews_groups, :overviews],
      [:overviews_groups, :groups],

      [:triggers, :users, column: :created_by_id],
      [:triggers, :users, column: :updated_by_id],

      [:jobs, :users, column: :created_by_id],
      [:jobs, :users, column: :updated_by_id],

      [:links, :link_types],

      [:postmaster_filters, :users, column: :created_by_id],
      [:postmaster_filters, :users, column: :updated_by_id],

      [:text_modules, :users],
      [:text_modules, :users, column: :created_by_id],
      [:text_modules, :users, column: :updated_by_id],

      [:text_modules_groups, :text_modules],
      [:text_modules_groups, :groups],

      [:templates, :users],
      [:templates, :users, column: :created_by_id],
      [:templates, :users, column: :updated_by_id],

      [:templates_groups, :templates],
      [:templates_groups, :groups],

      [:channels, :groups],
      [:channels, :users, column: :created_by_id],
      [:channels, :users, column: :updated_by_id],

      [:slas, :users, column: :created_by_id],
      [:slas, :users, column: :updated_by_id],

      [:macros, :users, column: :created_by_id],
      [:macros, :users, column: :updated_by_id],

      [:chats, :users, column: :created_by_id],
      [:chats, :users, column: :updated_by_id],

      [:chat_topics, :users, column: :created_by_id],
      [:chat_topics, :users, column: :updated_by_id],

      [:chat_sessions, :chats],
      [:chat_sessions, :users],
      [:chat_sessions, :users, column: :created_by_id],
      [:chat_sessions, :users, column: :updated_by_id],

      [:chat_messages, :chat_sessions],
      [:chat_messages, :users, column: :created_by_id],

      [:chat_agents, :users, column: :created_by_id],
      [:chat_agents, :users, column: :updated_by_id],

      [:report_profiles, :users, column: :created_by_id],
      [:report_profiles, :users, column: :updated_by_id],

      [:karma_users, :users],

      [:karma_activity_logs, :users],
      [:karma_activity_logs, :karma_activities, column: :activity_id],
    ]

    foreign_keys.each do |foreign_key|
      ActiveRecord::Base.transaction do
        begin
          add_foreign_key(*foreign_key)
        rescue => e
          Rails.logger.error "Inconsistent data status detected while adding foreign key '#{foreign_key.inspect}': #{e.message}"
        end
      end
    end
  end
end
