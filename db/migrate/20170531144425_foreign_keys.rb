# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ForeignKeys < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # remove wrong plural of ID columns
    ActiveRecord::Migration.rename_column :ticket_flags, :tickets_id, :ticket_id
    ActiveRecord::Migration.rename_column :ticket_article_flags, :ticket_articles_id, :ticket_article_id

    # add missing foreign keys
    foreign_keys = [
      # Base
      %i[users organizations],
      [:users, :users, { column: :created_by_id }],
      [:users, :users, { column: :updated_by_id }],

      [:signatures, :users, { column: :created_by_id }],
      [:signatures, :users, { column: :updated_by_id }],

      [:email_addresses, :users, { column: :created_by_id }],
      [:email_addresses, :users, { column: :updated_by_id }],

      %i[groups signatures],
      %i[groups email_addresses],
      [:groups, :users, { column: :created_by_id }],
      [:groups, :users, { column: :updated_by_id }],

      [:roles, :users, { column: :created_by_id }],
      [:roles, :users, { column: :updated_by_id }],

      [:organizations, :users, { column: :created_by_id }],
      [:organizations, :users, { column: :updated_by_id }],

      %i[roles_users users],
      %i[roles_users roles],

      %i[groups_users users],
      %i[groups_users groups],

      %i[organizations_users users],
      %i[organizations_users organizations],

      %i[authorizations users],

      [:translations, :users, { column: :created_by_id }],
      [:translations, :users, { column: :updated_by_id }],

      %i[tokens users],

      [:packages, :users, { column: :created_by_id }],
      [:packages, :users, { column: :updated_by_id }],

      %i[taskbars users],

      %i[tags tag_items],
      %i[tags tag_objects],
      [:tags, :users, { column: :created_by_id }],

      [:recent_views, :object_lookups, { column: :recent_view_object_id }],
      [:recent_views, :users, { column: :created_by_id }],

      [:activity_streams, :type_lookups, { column: :activity_stream_type_id }],
      [:activity_streams, :object_lookups, { column: :activity_stream_object_id }],
      %i[activity_streams permissions],
      %i[activity_streams groups],
      [:activity_streams, :users, { column: :created_by_id }],

      %i[histories history_types],
      %i[histories history_objects],
      %i[histories history_attributes],
      [:histories, :users, { column: :created_by_id }],

      %i[stores store_objects],
      %i[stores store_files],
      [:stores, :users, { column: :created_by_id }],

      [:avatars, :users, { column: :created_by_id }],
      [:avatars, :users, { column: :updated_by_id }],

      [:online_notifications, :users, { column: :created_by_id }],
      [:online_notifications, :users, { column: :updated_by_id }],

      [:schedulers, :users, { column: :created_by_id }],
      [:schedulers, :users, { column: :updated_by_id }],

      [:calendars, :users, { column: :created_by_id }],
      [:calendars, :users, { column: :updated_by_id }],

      %i[user_devices users],

      %i[object_manager_attributes object_lookups],
      [:object_manager_attributes, :users, { column: :created_by_id }],
      [:object_manager_attributes, :users, { column: :updated_by_id }],

      %i[cti_caller_ids users],

      [:stats_stores, :users, { column: :created_by_id }],

      [:http_logs, :users, { column: :created_by_id }],
      [:http_logs, :users, { column: :updated_by_id }],

      # Ticket
      [:ticket_state_types, :users, { column: :created_by_id }],
      [:ticket_state_types, :users, { column: :updated_by_id }],

      [:ticket_states, :ticket_state_types, { column: :state_type_id }],
      [:ticket_states, :users, { column: :created_by_id }],
      [:ticket_states, :users, { column: :updated_by_id }],

      [:ticket_priorities, :users, { column: :created_by_id }],
      [:ticket_priorities, :users, { column: :updated_by_id }],

      %i[tickets groups],
      [:tickets, :users, { column: :owner_id }],
      [:tickets, :users, { column: :customer_id }],
      [:tickets, :ticket_priorities, { column: :priority_id }],
      [:tickets, :ticket_states, { column: :state_id }],
      %i[tickets organizations],
      [:tickets, :users, { column: :created_by_id }],
      [:tickets, :users, { column: :updated_by_id }],

      [:ticket_flags, :tickets, { column: :ticket_id }],
      [:ticket_flags, :users, { column: :created_by_id }],

      [:ticket_article_types, :users, { column: :created_by_id }],
      [:ticket_article_types, :users, { column: :updated_by_id }],

      [:ticket_article_senders, :users, { column: :created_by_id }],
      [:ticket_article_senders, :users, { column: :updated_by_id }],

      %i[ticket_articles tickets],
      [:ticket_articles, :ticket_article_types, { column: :type_id }],
      [:ticket_articles, :ticket_article_senders, { column: :sender_id }],
      [:ticket_articles, :users, { column: :created_by_id }],
      [:ticket_articles, :users, { column: :updated_by_id }],
      [:ticket_articles, :users, { column: :origin_by_id }],

      [:ticket_article_flags, :ticket_articles, { column: :ticket_article_id }],
      [:ticket_article_flags, :users, { column: :created_by_id }],

      %i[ticket_time_accountings tickets],
      %i[ticket_time_accountings ticket_articles],
      [:ticket_time_accountings, :users, { column: :created_by_id }],

      [:overviews, :users, { column: :created_by_id }],
      [:overviews, :users, { column: :updated_by_id }],

      %i[overviews_roles overviews],
      %i[overviews_roles roles],

      %i[overviews_users overviews],
      %i[overviews_users users],

      %i[overviews_groups overviews],
      %i[overviews_groups groups],

      [:triggers, :users, { column: :created_by_id }],
      [:triggers, :users, { column: :updated_by_id }],

      [:jobs, :users, { column: :created_by_id }],
      [:jobs, :users, { column: :updated_by_id }],

      %i[links link_types],

      [:postmaster_filters, :users, { column: :created_by_id }],
      [:postmaster_filters, :users, { column: :updated_by_id }],

      %i[text_modules users],
      [:text_modules, :users, { column: :created_by_id }],
      [:text_modules, :users, { column: :updated_by_id }],

      %i[text_modules_groups text_modules],
      %i[text_modules_groups groups],

      %i[templates users],
      [:templates, :users, { column: :created_by_id }],
      [:templates, :users, { column: :updated_by_id }],

      %i[templates_groups templates],
      %i[templates_groups groups],

      %i[channels groups],
      [:channels, :users, { column: :created_by_id }],
      [:channels, :users, { column: :updated_by_id }],

      [:slas, :users, { column: :created_by_id }],
      [:slas, :users, { column: :updated_by_id }],

      [:macros, :users, { column: :created_by_id }],
      [:macros, :users, { column: :updated_by_id }],

      [:chats, :users, { column: :created_by_id }],
      [:chats, :users, { column: :updated_by_id }],

      %i[chat_sessions chats],
      %i[chat_sessions users],
      [:chat_sessions, :users, { column: :created_by_id }],
      [:chat_sessions, :users, { column: :updated_by_id }],

      %i[chat_messages chat_sessions],
      [:chat_messages, :users, { column: :created_by_id }],

      [:chat_agents, :users, { column: :created_by_id }],
      [:chat_agents, :users, { column: :updated_by_id }],

      [:report_profiles, :users, { column: :created_by_id }],
      [:report_profiles, :users, { column: :updated_by_id }],

      %i[karma_users users],

      %i[karma_activity_logs users],
      [:karma_activity_logs, :karma_activities, { column: :activity_id }],
    ]

    foreign_keys.each do |foreign_key|
      ActiveRecord::Base.transaction do

        add_foreign_key(*foreign_key)
      rescue => e
        Rails.logger.error "Inconsistent data status detected while adding foreign key '#{foreign_key.inspect}': #{e.message}"

      end
    end
  end
end
