# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CreateBase < ActiveRecord::Migration[4.2]
  def up

    # clear old caches to start from scratch
    Cache.clear

    create_table :sessions do |t|
      t.string :session_id,  null: false
      t.boolean :persistent, null: true
      t.text :data
      t.timestamps limit: 3, null: false
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at
    add_index :sessions, :persistent

    create_table :users do |t|
      t.references :organization,                 null: true
      t.string :login,                limit: 255, null: false
      t.string :firstname,            limit: 100, null: true, default: ''
      t.string :lastname,             limit: 100, null: true, default: ''
      t.string :email,                limit: 255, null: true, default: ''
      t.string :image,                limit: 100, null: true
      t.string :image_source,         limit: 200, null: true
      t.string :web,                  limit: 100, null: true, default: ''
      t.string :password,             limit: 100, null: true
      t.string :phone,                limit: 100, null: true, default: ''
      t.string :fax,                  limit: 100, null: true, default: ''
      t.string :mobile,               limit: 100, null: true, default: ''
      t.string :department,           limit: 200, null: true, default: ''
      t.string :street,               limit: 120, null: true, default: ''
      t.string :zip,                  limit: 100, null: true, default: ''
      t.string :city,                 limit: 100, null: true, default: ''
      t.string :country,              limit: 100, null: true, default: ''
      t.string :address,              limit: 500, null: true, default: ''
      t.boolean :vip,                                         default: false
      t.boolean :verified,                        null: false, default: false
      t.boolean :active,                          null: false, default: true
      t.string :note,                 limit: 5000, null: true, default: ''
      t.timestamp :last_login,        limit: 3,   null: true
      t.string :source,               limit: 200, null: true
      t.integer :login_failed,                    null: false, default: 0
      t.boolean :out_of_office,                   null: false, default: false
      t.date :out_of_office_start_at,             null: true
      t.date :out_of_office_end_at,               null: true
      t.integer :out_of_office_replacement_id,    null: true
      t.string :preferences,          limit: 8000, null: true
      t.integer :updated_by_id,                   null: false
      t.integer :created_by_id,                   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :users, [:login], unique: true
    add_index :users, [:email]
    #add_index :users, [:email], unique: => true
    add_index :users, [:organization_id]
    add_index :users, [:image]
    add_index :users, [:department]
    add_index :users, [:phone]
    add_index :users, [:fax]
    add_index :users, [:mobile]
    add_index :users, %i[out_of_office out_of_office_start_at out_of_office_end_at], name: 'index_out_of_office'
    add_index :users, [:out_of_office_replacement_id]
    add_index :users, [:source]
    add_index :users, [:created_by_id]
    add_foreign_key :users, :users, column: :created_by_id
    add_foreign_key :users, :users, column: :updated_by_id
    add_foreign_key :users, :users, column: :out_of_office_replacement_id

    create_table :signatures do |t|
      t.string :name,                 limit: 100,  null: false
      t.text :body,                   limit: 10.megabytes + 1, null: true
      t.boolean :active,                           null: false, default: true
      t.string :note,                 limit: 250,  null: true
      t.integer :updated_by_id,                    null: false
      t.integer :created_by_id,                    null: false
      t.timestamps limit: 3, null: false
    end
    add_index :signatures, [:name], unique: true
    add_foreign_key :signatures, :users, column: :created_by_id
    add_foreign_key :signatures, :users, column: :updated_by_id

    create_table :email_addresses do |t|
      t.integer :channel_id,                        null: true
      t.string  :realname,             limit: 250,  null: false
      t.string  :email,                limit: 250,  null: false
      t.boolean :active,                            null: false, default: true
      t.string  :note,                 limit: 250,  null: true
      t.string  :preferences,          limit: 2000, null: true
      t.integer :updated_by_id,                     null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :email_addresses, [:email], unique: true
    add_foreign_key :email_addresses, :users, column: :created_by_id
    add_foreign_key :email_addresses, :users, column: :updated_by_id

    create_table :groups do |t|
      t.references :signature,                      null: true
      t.references :email_address,                  null: true
      t.string :name,                   limit: 160, null: false
      t.integer :assignment_timeout,                null: true
      t.string :follow_up_possible,     limit: 100, null: false, default: 'yes'
      t.boolean :follow_up_assignment,              null: false, default: true
      t.boolean :active,                            null: false, default: true
      t.string :note,                   limit: 250, null: true
      t.integer :updated_by_id,                     null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :groups, [:name], unique: true
    add_foreign_key :groups, :signatures
    add_foreign_key :groups, :email_addresses
    add_foreign_key :groups, :users, column: :created_by_id
    add_foreign_key :groups, :users, column: :updated_by_id

    create_table :roles do |t|
      t.string :name,                   limit: 100, null: false
      t.text   :preferences,            limit: 500.kilobytes + 1, null: true
      t.boolean :default_at_signup,                 null: true, default: false
      t.boolean :active,                            null: false, default: true
      t.string :note,                   limit: 250, null: true
      t.integer :updated_by_id,                     null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :roles, [:name], unique: true
    add_foreign_key :roles, :users, column: :created_by_id
    add_foreign_key :roles, :users, column: :updated_by_id

    create_table :permissions do |t|
      t.string :name,          limit: 255, null: false
      t.string :note,          limit: 500, null: true
      t.string :preferences,   limit: 10_000, null: true
      t.boolean :active,       null: false, default: true
      t.boolean :allow_signup, null: false, default: false
      t.timestamps limit: 3,   null: false
    end
    add_index :permissions, [:name], unique: true

    create_table :permissions_roles, id: false do |t|
      t.belongs_to :role, index: true
      t.belongs_to :permission, index: true
    end

    create_table :organizations do |t|
      t.string :name,                   limit: 100, null: false
      t.boolean :shared,                            null: false, default: true
      t.string :domain,                 limit: 250, null: true,  default: ''
      t.boolean :domain_assignment,                 null: false, default: false
      t.boolean :active,                            null: false, default: true
      t.string :note,                   limit: 5000, null: true,  default: ''
      t.integer :updated_by_id,                     null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3,   null: false
    end
    add_index :organizations, [:name], unique: true
    add_index :organizations, [:domain]
    add_foreign_key :users, :organizations
    add_foreign_key :organizations, :users, column: :created_by_id
    add_foreign_key :organizations, :users, column: :updated_by_id

    create_table :roles_users, id: false do |t|
      t.references :user
      t.references :role
    end
    add_index :roles_users, [:user_id]
    add_index :roles_users, [:role_id]
    add_foreign_key :roles_users, :users
    add_foreign_key :roles_users, :roles

    create_table :groups_users, id: false do |t|
      t.references :user,                null: false
      t.references :group,               null: false
      t.string :access,       limit: 50, null: false, default: 'full'
    end
    add_index :groups_users, [:user_id]
    add_index :groups_users, [:group_id]
    add_index :groups_users, [:access]
    add_foreign_key :groups_users, :users
    add_foreign_key :groups_users, :groups

    create_table :roles_groups, id: false do |t|
      t.references :role,                null: false
      t.references :group,               null: false
      t.string :access,       limit: 50, null: false, default: 'full'
    end
    add_index :roles_groups, [:role_id]
    add_index :roles_groups, [:group_id]
    add_index :roles_groups, [:access]
    add_foreign_key :roles_groups, :roles
    add_foreign_key :roles_groups, :groups

    create_table :organizations_users, id: false do |t|
      t.references :user
      t.references :organization
    end
    add_index :organizations_users, [:user_id]
    add_index :organizations_users, [:organization_id]
    add_foreign_key :organizations_users, :users
    add_foreign_key :organizations_users, :organizations

    create_table :authorizations do |t|
      t.string :provider,             limit: 250, null: false
      t.string :uid,                  limit: 250, null: false
      t.string :token,                limit: 2500, null: true
      t.string :secret,               limit: 250, null: true
      t.string :username,             limit: 250, null: true
      t.references :user, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :authorizations, %i[uid provider], unique: true
    add_index :authorizations, [:user_id]
    add_index :authorizations, [:username]
    add_foreign_key :authorizations, :users

    create_table :locales do |t|
      t.string  :locale,              limit: 20,  null: false
      t.string  :alias,               limit: 20,  null: true
      t.string  :name,                limit: 255, null: false
      t.string  :dir,                 limit: 9,   null: false, default: 'ltr'
      t.boolean :active,                          null: false, default: true
      t.timestamps limit: 3, null: false
    end
    add_index :locales, [:locale], unique: true
    add_index :locales, [:name], unique: true

    create_table :translations do |t|
      t.string :locale,               limit: 10,   null: false
      t.string :source,               limit: 500,  null: false
      t.string :target,               limit: 500,  null: false
      t.string :target_initial,       limit: 500,  null: false
      t.string :format,               limit: 20,   null: false, default: 'string'
      t.integer :updated_by_id,                    null: false
      t.integer :created_by_id,                    null: false
      t.timestamps limit: 3, null: false
    end
    add_index :translations, [:source], length: 255
    add_index :translations, [:locale]
    add_foreign_key :translations, :users, column: :created_by_id
    add_foreign_key :translations, :users, column: :updated_by_id

    create_table :object_lookups do |t|
      t.string :name,                 limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :object_lookups, [:name], unique: true

    create_table :type_lookups do |t|
      t.string :name,                 limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :type_lookups, [:name],   unique: true

    create_table :tokens do |t|
      t.references :user,                         null: false
      t.boolean :persistent
      t.string  :name,                limit: 100, null: false
      t.string  :action,              limit: 40,  null: false
      t.string  :label,               limit: 255, null: true
      t.text    :preferences,         limit: 500.kilobytes + 1, null: true
      t.timestamp :last_used_at,      limit: 3,   null: true
      t.date :expires_at,                         null: true
      t.timestamps limit: 3, null: false
    end
    add_index :tokens, :user_id
    add_index :tokens, %i[name action], unique: true
    add_index :tokens, :created_at
    add_index :tokens, :persistent
    add_foreign_key :tokens, :users

    create_table :packages do |t|
      t.string :name,                 limit: 250, null: false
      t.string :version,              limit: 50,  null: false
      t.string :vendor,               limit: 150, null: false
      t.string :state,                limit: 50,  null: false
      t.integer :updated_by_id,                   null: false
      t.integer :created_by_id,                   null: false
      t.timestamps limit: 3, null: false
    end
    add_foreign_key :packages, :users, column: :created_by_id
    add_foreign_key :packages, :users, column: :updated_by_id

    create_table :package_migrations do |t|
      t.string :name,                 limit: 250, null: false
      t.string :version,              limit: 250, null: false
      t.timestamps limit: 3, null: false
    end

    create_table :taskbars do |t|
      t.references :user,                           null: false
      t.datetime :last_contact,                     null: false, limit: 3
      t.string :client_id,                          null: false
      t.string :key,                   limit: 100,  null: false
      t.string :callback,              limit: 100,  null: false
      t.text :state,                   limit: 20.megabytes + 1, null: true
      t.text :preferences,             limit: 5.megabytes + 1, null: true
      t.string :params,                limit: 2000, null: true
      t.integer :prio,                              null: false
      t.boolean :notify,                            null: false, default: false
      t.boolean :active,                            null: false, default: false
      t.timestamps limit: 3, null: false
    end
    add_index :taskbars, [:user_id]
    add_index :taskbars, [:client_id]
    add_index :taskbars, [:key]
    add_foreign_key :taskbars, :users

    create_table :tag_objects do |t|
      t.string :name,                   limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :tag_objects, [:name], unique: true

    create_table :tag_items do |t|
      t.string :name,                   limit: 250, null: false
      t.string :name_downcase,          limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :tag_items, [:name_downcase]

    create_table :tags do |t|
      t.references :tag_item,                       null: false
      t.references :tag_object,                     null: false
      t.integer :o_id,                              null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :tags, [:o_id]
    add_index :tags, [:tag_object_id]
    add_foreign_key :tags, :tag_items
    add_foreign_key :tags, :tag_objects
    add_foreign_key :tags, :users, column: :created_by_id

    create_table :recent_views do |t|
      t.references :recent_view_object,             null: false
      t.integer :o_id,                              null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :recent_views, [:o_id]
    add_index :recent_views, [:created_by_id]
    add_index :recent_views, [:created_at]
    add_index :recent_views, [:recent_view_object_id]
    add_foreign_key :recent_views, :object_lookups, column: :recent_view_object_id
    add_foreign_key :recent_views, :users, column: :created_by_id

    create_table :activity_streams do |t|
      t.references :activity_stream_type,           null: false
      t.references :activity_stream_object,         null: false
      t.references :permission,                     null: true
      t.references :group,                          null: true
      t.integer :o_id,                              null: false
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :activity_streams, [:o_id]
    add_index :activity_streams, [:created_by_id]
    add_index :activity_streams, [:permission_id]
    add_index :activity_streams, %i[permission_id group_id]
    add_index :activity_streams, %i[permission_id group_id created_at], name: 'index_activity_streams_on_permission_id_group_id_created_at'
    add_index :activity_streams, [:group_id]
    add_index :activity_streams, [:created_at]
    add_index :activity_streams, [:activity_stream_object_id]
    add_index :activity_streams, [:activity_stream_type_id]
    add_foreign_key :activity_streams, :type_lookups, column: :activity_stream_type_id
    add_foreign_key :activity_streams, :object_lookups, column: :activity_stream_object_id
    add_foreign_key :activity_streams, :permissions
    add_foreign_key :activity_streams, :groups
    add_foreign_key :activity_streams, :users, column: :created_by_id

    create_table :history_types do |t|
      t.string :name,                   limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :history_types, [:name], unique: true

    create_table :history_objects do |t|
      t.string :name,                   limit: 250, null: false
      t.string :note,                   limit: 250, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :history_objects, [:name], unique: true

    create_table :history_attributes do |t|
      t.string :name,                   limit: 250, null: false
      t.timestamps limit: 3, null: false
    end
    add_index :history_attributes, [:name], unique: true

    create_table :histories do |t|
      t.references :history_type,                   null: false
      t.references :history_object,                 null: false
      t.references :history_attribute,              null: true
      t.integer :o_id,                              null: false
      t.integer :related_o_id,                      null: true
      t.integer :related_history_object_id,         null: true
      t.integer :id_to,                             null: true
      t.integer :id_from,                           null: true
      t.string :value_from,            limit: 500,  null: true
      t.string :value_to,              limit: 500,  null: true
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :histories, [:o_id]
    add_index :histories, [:created_by_id]
    add_index :histories, [:created_at]
    add_index :histories, [:history_object_id]
    add_index :histories, [:history_attribute_id]
    add_index :histories, [:history_type_id]
    add_index :histories, [:id_to]
    add_index :histories, [:id_from]
    add_index :histories, [:value_from], length: 255
    add_index :histories, [:value_to], length: 255
    add_index :histories, [:related_o_id]
    add_index :histories, [:related_history_object_id]
    add_index :histories, %i[o_id history_object_id related_o_id]
    add_foreign_key :histories, :history_types
    add_foreign_key :histories, :history_objects
    add_foreign_key :histories, :history_attributes
    add_foreign_key :histories, :users, column: :created_by_id

    create_table :settings do |t|
      t.string :title,                  limit: 200,  null: false
      t.string :name,                   limit: 200,  null: false
      t.string :area,                   limit: 100,  null: false
      t.string :description,            limit: 2000, null: false
      t.text :options, null: true
      t.text :state_current,            limit: 200.kilobytes + 1, null: true
      t.string :state_initial,          limit: 2000, null: true
      t.boolean :frontend,                           null: false
      t.text :preferences,              limit: 200.kilobytes + 1, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :settings, [:name], unique: true
    add_index :settings, [:area]
    add_index :settings, [:frontend]

    create_table :store_objects do |t|
      t.string :name,               limit: 250, null: false
      t.string :note,               limit: 250, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :store_objects, [:name], unique: true

    create_table :store_files do |t|
      t.string :sha,                limit: 128, null: false
      t.string :provider,           limit: 20,  null: true
      t.timestamps limit: 3, null: false
    end
    add_index :store_files, [:sha], unique: true
    add_index :store_files, [:provider]

    create_table :stores do |t|
      t.references :store_object,               null: false
      t.references :store_file,                 null: false
      t.integer :o_id,              limit: 8,   null: false
      t.string :preferences,        limit: 2500, null: true
      t.string :size,               limit: 50,  null: true
      t.string :filename,           limit: 250, null: false
      t.integer :created_by_id,                 null: false
      t.timestamps limit: 3, null: false
    end
    add_index :stores, %i[store_object_id o_id]
    add_index :stores, %i[store_file_id]
    add_foreign_key :stores, :store_objects
    add_foreign_key :stores, :store_files
    add_foreign_key :stores, :users, column: :created_by_id

    create_table :store_provider_dbs do |t|
      t.string :sha,                limit: 128,            null: false
      t.binary :data,               limit: 200.megabytes,  null: true
      t.timestamps limit: 3, null: false
    end
    add_index :store_provider_dbs, [:sha], unique: true

    create_table :avatars do |t|
      t.integer :o_id,                          null: false
      t.integer :object_lookup_id,              null: false
      t.boolean :default,                       null: false, default: false
      t.boolean :deletable,                     null: false, default: true
      t.boolean :initial,                       null: false, default: false
      t.integer :store_full_id,                 null: true
      t.integer :store_resize_id,               null: true
      t.string :store_hash,         limit: 32,  null: true
      t.string :source,             limit: 100, null: false
      t.string :source_url,         limit: 512, null: true
      t.integer :updated_by_id,                 null: false
      t.integer :created_by_id,                 null: false
      t.timestamps limit: 3, null: false
    end
    add_index :avatars, %i[o_id object_lookup_id]
    add_index :avatars, [:store_hash]
    add_index :avatars, [:source]
    add_index :avatars, [:default]
    add_foreign_key :avatars, :users, column: :created_by_id
    add_foreign_key :avatars, :users, column: :updated_by_id

    create_table :online_notifications do |t|
      t.integer :o_id,                          null: false
      t.integer :object_lookup_id,              null: false
      t.integer :type_lookup_id,                null: false
      t.integer :user_id,                       null: false
      t.boolean :seen,                          null: false, default: false
      t.integer :updated_by_id,                 null: false
      t.integer :created_by_id,                 null: false
      t.timestamps limit: 3, null: false
    end
    add_index :online_notifications, [:user_id]
    add_index :online_notifications, [:seen]
    add_index :online_notifications, [:created_at]
    add_index :online_notifications, [:updated_at]
    add_foreign_key :online_notifications, :users
    add_foreign_key :online_notifications, :users, column: :created_by_id
    add_foreign_key :online_notifications, :users, column: :updated_by_id

    create_table :schedulers do |t|
      t.string :name,                     limit: 250,   null: false
      t.string :method,                   limit: 250,   null: false
      t.integer :period,                                null: true
      t.integer :running,                               null: false, default: false
      t.timestamp :last_run,              limit: 3,     null: true
      t.integer :prio,                                  null: false
      t.string :pid,                      limit: 250,   null: true
      t.string :note,                     limit: 250,   null: true
      t.string :error_message,                          null: true
      t.string :status,                                 null: true
      t.boolean :active,                                null: false, default: false
      t.integer :updated_by_id,                         null: false
      t.integer :created_by_id,                         null: false
      t.timestamps limit: 3, null: false
    end
    add_index :schedulers, [:name], unique: true
    add_foreign_key :schedulers, :users, column: :created_by_id
    add_foreign_key :schedulers, :users, column: :updated_by_id

    create_table :calendars do |t|
      t.string  :name,                   limit: 250,  null: true
      t.string  :timezone,               limit: 250,  null: true
      t.string  :business_hours,         limit: 3000, null: true
      t.boolean :default,                             null: false, default: false
      t.string  :ical_url,               limit: 500,  null: true
      t.text    :public_holidays,        limit: 500.kilobytes + 1, null: true
      t.text    :last_log,               limit: 500.kilobytes + 1, null: true
      t.timestamp :last_sync,            limit: 3,    null: true
      t.integer :updated_by_id,                       null: false
      t.integer :created_by_id,                       null: false
      t.timestamps limit: 3, null: false
    end
    add_index :calendars, [:name], unique: true
    add_foreign_key :calendars, :users, column: :created_by_id
    add_foreign_key :calendars, :users, column: :updated_by_id

    create_table :user_devices do |t|
      t.references :user,             null: false
      t.string  :name,                 limit: 250, null: false
      t.string  :os,                   limit: 150, null: true
      t.string  :browser,              limit: 250, null: true
      t.string  :location,             limit: 150, null: true
      t.string  :device_details,       limit: 2500, null: true
      t.string  :location_details,     limit: 2500, null: true
      t.string  :fingerprint,          limit: 160, null: true
      t.string  :user_agent,           limit: 250, null: true
      t.string  :ip,                   limit: 160, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :user_devices, [:user_id]
    add_index :user_devices, %i[os browser location]
    add_index :user_devices, [:fingerprint]
    add_index :user_devices, [:updated_at]
    add_index :user_devices, [:created_at]
    add_foreign_key :user_devices, :users

    create_table :external_credentials do |t|
      t.string :name
      t.string :credentials, limit: 2500, null: false
      t.timestamps limit: 3, null: false
    end

    create_table :object_manager_attributes do |t|
      t.references :object_lookup,                          null: false
      t.string :name,                         limit: 200,   null: false
      t.string :display,                      limit: 200,   null: false
      t.string :data_type,                    limit: 100,   null: false
      t.text :data_option,                    limit: 800.kilobytes + 1,  null: true
      t.text :data_option_new,                limit: 800.kilobytes + 1,  null: true
      t.boolean :editable,                                  null: false, default: true
      t.boolean :active,                                    null: false, default: true
      t.string :screens,                      limit: 2000,  null: true
      t.boolean :to_create,                                 null: false, default: false
      t.boolean :to_migrate,                                null: false, default: false
      t.boolean :to_delete,                                 null: false, default: false
      t.boolean :to_config,                                 null: false, default: false
      t.integer :position,                                  null: false
      t.integer :created_by_id,                             null: false
      t.integer :updated_by_id,                             null: false
      t.timestamps limit: 3, null: false
    end
    add_index :object_manager_attributes, %i[object_lookup_id name],   unique: true
    add_index :object_manager_attributes, [:object_lookup_id]
    add_foreign_key :object_manager_attributes, :object_lookups
    add_foreign_key :object_manager_attributes, :users, column: :created_by_id
    add_foreign_key :object_manager_attributes, :users, column: :updated_by_id

    create_table :delayed_jobs, force: true do |t|
      t.integer  :priority, default: 0         # Allows some jobs to jump to the front of the queue
      t.integer  :attempts, default: 0         # Provides for retries, but still fail eventually.
      t.text     :handler                      # YAML-encoded string of the object that will do work
      t.text     :last_error                   # reason for last failure (See Note below)
      t.datetime :run_at, limit: 3             # When to run. Could be Time.zone.now for immediately, or sometime in the future.
      t.datetime :locked_at, limit: 3          # Set when a client is working on this object
      t.datetime :failed_at, limit: 3          # Set when all retries have failed (actually, by default, the record is deleted instead)
      t.string   :locked_by                    # Who is working on this object (if locked)
      t.string   :queue                        # The name of the queue this job is in
      t.timestamps limit: 3, null: false
    end

    add_index :delayed_jobs, %i[priority run_at], name: 'delayed_jobs_priority'

    create_table :external_syncs do |t|
      t.string  :source,                 limit: 100,  null: false
      t.string  :source_id,              limit: 200,  null: false
      t.string  :object,                 limit: 100,  null: false
      t.integer :o_id,                                null: false
      t.text    :last_payload,           limit: 500.kilobytes + 1, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :external_syncs, %i[source source_id], unique: true
    add_index :external_syncs, %i[source source_id object o_id], name: 'index_external_syncs_on_source_and_source_id_and_object_o_id'
    add_index :external_syncs, %i[object o_id]

    create_table :import_jobs do |t|
      t.string :name, limit: 250, null: false

      t.boolean :dry_run, default: false

      t.text :payload, limit: 80_000
      t.text :result, limit: 80_000

      t.datetime :started_at, limit: 3
      t.datetime :finished_at, limit: 3

      t.timestamps limit: 3, null: false
    end

    create_table :cti_logs do |t|
      t.string  :direction,              limit: 20,   null: false
      t.string  :state,                  limit: 20,   null: false
      t.string  :from,                   limit: 100,  null: false
      t.string  :from_comment,           limit: 250,  null: true
      t.string  :to,                     limit: 100,  null: false
      t.string  :to_comment,             limit: 250,  null: true
      t.string  :queue,                  limit: 250,  null: true
      t.string  :call_id,                limit: 250,  null: false
      t.string  :comment,                limit: 500,  null: true
      t.timestamp :initialized_at,       limit: 3,    null: true
      t.timestamp :start_at,             limit: 3,    null: true
      t.timestamp :end_at,               limit: 3,    null: true
      t.integer   :duration_waiting_time,             null: true
      t.integer   :duration_talking_time,             null: true
      t.boolean   :done,                              null: false, default: true
      t.text :preferences,            limit: 500.kilobytes + 1, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :cti_logs, [:call_id], unique: true
    add_index :cti_logs, [:direction]
    add_index :cti_logs, [:from]

    create_table :cti_caller_ids do |t|
      t.string     :caller_id,              limit: 100, null: false
      t.string     :comment,                limit: 500, null: true
      t.string     :level,                  limit: 100, null: false
      t.string     :object,                 limit: 100, null: false
      t.integer    :o_id,                               null: false
      t.references :user,                            null: true
      t.text       :preferences,            limit: 500.kilobytes + 1, null: true
      t.timestamps limit: 3, null: false
    end
    add_index :cti_caller_ids, [:caller_id]
    add_index :cti_caller_ids, %i[caller_id level]
    add_index :cti_caller_ids, %i[caller_id user_id]
    add_index :cti_caller_ids, %i[object o_id]
    add_index :cti_caller_ids, %i[object o_id level user_id caller_id], name: 'index_cti_caller_ids_on_object_o_id_level_user_id_caller_id'
    add_foreign_key :cti_caller_ids, :users

    create_table :stats_stores do |t|
      t.references :stats_storable, polymorphic: true, index: true
      t.string  :key,                   limit: 250, null: true
      t.string  :data,                 limit: 5000, null: true
      t.integer :created_by_id,                     null: false
      t.timestamps limit: 3, null: false
    end
    add_index :stats_stores, [:key]
    add_index :stats_stores, [:created_by_id]
    add_index :stats_stores, [:created_at]
    add_foreign_key :stats_stores, :users, column: :created_by_id

    create_table :http_logs do |t|
      t.column :direction,            :string, limit: 20,    null: false
      t.column :facility,             :string, limit: 100,   null: false
      t.column :method,               :string, limit: 100,   null: false
      t.column :url,                  :string, limit: 255,   null: false
      t.column :status,               :string, limit: 20,    null: true
      t.column :ip,                   :string, limit: 50,    null: true
      t.column :request,              :string, limit: 10_000, null: false
      t.column :response,             :string, limit: 10_000, null: false
      t.column :updated_by_id,        :integer,              null: true
      t.column :created_by_id,        :integer,              null: true
      t.timestamps limit: 3, null: false
    end
    add_index :http_logs, [:facility]
    add_index :http_logs, [:created_by_id]
    add_index :http_logs, [:created_at]
    add_foreign_key :http_logs, :users, column: :created_by_id
    add_foreign_key :http_logs, :users, column: :updated_by_id

    create_table :active_job_locks do |t|
      t.string :lock_key
      t.string :active_job_id

      t.timestamps limit: 3
    end
    add_index :active_job_locks, :lock_key, unique: true
    add_index :active_job_locks, :active_job_id, unique: true

    create_table :smime_certificates do |t|
      t.string :subject,            limit: 500,  null: false
      t.string :doc_hash,           limit: 250,  null: false
      t.string :fingerprint,        limit: 250,  null: false
      t.string :modulus,            limit: 1024, null: false
      t.datetime :not_before_at,                 null: true, limit: 3
      t.datetime :not_after_at,                  null: true, limit: 3
      t.binary :raw,                limit: 10.megabytes,  null: false
      t.binary :private_key,        limit: 10.megabytes,  null: true
      t.string :private_key_secret, limit: 500,  null: true
      t.timestamps limit: 3, null: false
    end
    add_index :smime_certificates, [:fingerprint], unique: true
    add_index :smime_certificates, [:modulus]
    add_index :smime_certificates, [:subject]

    create_table :data_privacy_tasks do |t|
      t.column :state,                :string, limit: 150, default: 'in process', null: true
      t.references :deletable,        polymorphic: true
      t.text :preferences
      t.column :updated_by_id,        :integer,                                   null: false
      t.column :created_by_id,        :integer,                                   null: false
      t.timestamps limit: 3, null: false
    end
    add_index :data_privacy_tasks, [:state]

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
  end
end
