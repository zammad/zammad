class CreateBase < ActiveRecord::Migration
  def up

    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end
    add_index :sessions, :session_id
    add_index :sessions, :updated_at

    create_table :users do |t|
      t.references :organization,                       :null => true
      t.column :login,          :string, :limit => 100, :null => false
      t.column :firstname,      :string, :limit => 100, :null => true
      t.column :lastname,       :string, :limit => 100, :null => true
      t.column :email,          :string, :limit => 140, :null => true
      t.column :image,          :string, :limit => 100, :null => true
      t.column :image_source,   :string, :limit => 200, :null => true
      t.column :web,            :string, :limit => 100, :null => true
      t.column :password,       :string, :limit => 100, :null => true
      t.column :phone,          :string, :limit => 100, :null => true
      t.column :fax,            :string, :limit => 100, :null => true
      t.column :mobile,         :string, :limit => 100, :null => true
      t.column :department,     :string, :limit => 200, :null => true
      t.column :street,         :string, :limit => 120, :null => true
      t.column :zip,            :string, :limit => 100, :null => true
      t.column :city,           :string, :limit => 100, :null => true
      t.column :country,        :string, :limit => 100, :null => true
      t.column :verified,       :boolean,               :null => false, :default => false
      t.column :active,         :boolean,               :null => false, :default => true
      t.column :note,           :string, :limit => 250, :null => true
      t.column :last_login,     :timestamp,             :null => true
      t.column :source,         :string, :limit => 200, :null => true
      t.column :login_failed,   :integer,               :null => false, :default => 0
      t.column :preferences,    :string, :limit => 8000,:null => true
      t.column :updated_by_id,  :integer,               :null => false
      t.column :created_by_id,  :integer,               :null => false
      t.timestamps
    end
    add_index :users, [:login], :unique => true
    add_index :users, [:email]
#    add_index :users, [:email], :unique => true
    add_index :users, [:image]
    add_index :users, [:department]
    add_index :users, [:phone]
    add_index :users, [:fax]
    add_index :users, [:mobile]
    add_index :users, [:source]
    add_index :users, [:created_by_id]


    create_table :signatures do |t|
      t.column :name,           :string, :limit => 100,  :null => false
      t.column :body,           :string, :limit => 5000, :null => true
      t.column :active,         :boolean,                :null => false, :default => true
      t.column :note,           :string, :limit => 250,  :null => true
      t.column :updated_by_id,  :integer,                :null => false
      t.column :created_by_id,  :integer,                :null => false
      t.timestamps
    end
    add_index :signatures, [:name], :unique => true


    create_table :email_addresses do |t|
      t.column :realname,       :string, :limit => 250,  :null => false
      t.column :email,          :string, :limit => 250,  :null => false
      t.column :active,         :boolean,                :null => false, :default => true
      t.column :note,           :string, :limit => 250,  :null => true
      t.column :updated_by_id,  :integer,                :null => false
      t.column :created_by_id,  :integer,                :null => false
      t.timestamps
    end
    add_index :email_addresses, [:email], :unique => true


    create_table :groups do |t|
      t.references :signature,                                 :null => true
      t.references :email_address,                             :null => true
      t.column :name,                 :string,  :limit => 100, :null => false
      t.column :assignment_timeout,   :integer,                :null => true
      t.column :follow_up_possible,   :string,  :limit => 100, :null => false, :default => 'yes'
      t.column :follow_up_assignment, :boolean,                :null => false, :default => true
      t.column :active,               :boolean,                :null => false, :default => true
      t.column :note,                 :string,  :limit => 250, :null => true
      t.column :updated_by_id,        :integer,                :null => false
      t.column :created_by_id,        :integer,                :null => false
      t.timestamps
    end
    add_index :groups, [:name], :unique => true

    create_table :roles do |t|
      t.column :name,                 :string, :limit => 100, :null => false
      t.column :active,               :boolean,               :null => false, :default => true
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :roles, [:name], :unique => true


    create_table :organizations do |t|
      t.column :name,                 :string, :limit => 100, :null => false
      t.column :shared,               :boolean,               :null => false, :default => true
      t.column :active,               :boolean,               :null => false, :default => true
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :organizations, [:name], :unique => true

    create_table :roles_users, :id => false do |t|
      t.integer :user_id
      t.integer :role_id
    end

    create_table :groups_users, :id => false do |t|
      t.integer :user_id
      t.integer :group_id
    end

    create_table :organizations_users, :id => false do |t|
      t.integer :user_id
      t.integer :organization_id
    end


    create_table :authorizations do |t|
      t.string :provider, :limit => 250, :null => false
      t.string :uid,      :limit => 250, :null => false
      t.string :token,    :limit => 250, :null => true
      t.string :secret,   :limit => 250, :null => true
      t.string :username, :limit => 250, :null => true
      t.references :user, :null => false
      t.timestamps
    end
    add_index :authorizations, [:uid, :provider]
    add_index :authorizations, [:user_id]
    add_index :authorizations, [:username]


    create_table :translations do |t|
      t.column :locale,               :string,  :limit => 10,   :null => false
      t.column :source,               :string,  :limit => 255,  :null => false
      t.column :target,               :string,  :limit => 255,  :null => false
      t.column :target_initial,       :string,  :limit => 255,  :null => false
      t.column :updated_by_id,        :integer,                 :null => false
      t.column :created_by_id,        :integer,                 :null => false
      t.timestamps
    end
    add_index :translations, [:source]
    add_index :translations, [:locale]


    create_table :object_lookups do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :object_lookups, [:name],   :unique => true

    create_table :type_lookups do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :type_lookups, [:name],   :unique => true


    create_table :tokens do |t|
      t.references :user,                 :null => false
      t.string :name,     :limit => 100,  :null => false
      t.string :action,   :limit => 40,   :null => false
      t.timestamps
    end
    add_index :tokens, :user_id
    add_index :tokens, [:name, :action], :unique => true
    add_index :tokens, :created_at


    create_table :packages do |t|
      t.column :name,                 :string, :limit => 250,   :null => false
      t.column :version,              :string, :limit => 50,    :null => false
      t.column :vendor,               :string, :limit => 150,   :null => false
      t.column :state,                :string, :limit => 50,    :null => false
      t.column :updated_by_id,        :integer,                 :null => false
      t.column :created_by_id,        :integer,                 :null => false
      t.timestamps
    end
    create_table :package_migrations do |t|
      t.column :name,                 :string, :limit => 250,   :null => false
      t.column :version,              :string, :limit => 250,   :null => false
      t.timestamps
    end

    create_table :taskbars do |t|
      t.column :user_id,            :integer,   :null => false
      t.column :last_contact,       :datetime,  :null => false
      t.column :client_id,          :string,    :null => false
      t.column :key,                :string,    :limit => 100,  :null => false
      t.column :callback,           :string,    :limit => 100,  :null => false
      t.column :state,              :string,    :limit => 8000, :null => true
      t.column :params,             :string,    :limit => 2000, :null => true
      t.column :prio,               :integer,   :null => false
      t.column :notify,             :boolean,   :null => false, :default => false
      t.column :active,             :boolean,   :null => false, :default => false
      t.timestamps
    end
    add_index :taskbars, [:user_id]
    add_index :taskbars, [:client_id]


    create_table :tags do |t|
      t.references :tag_item,                           :null => false
      t.references :tag_object,                         :null => false
      t.column :o_id,                       :integer,   :null => false
      t.column :created_by_id,              :integer,   :null => false
      t.timestamps
    end
    add_index :tags, [:o_id]
    add_index :tags, [:tag_object_id]

    create_table :tag_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :tag_objects, [:name],    :unique => true

    create_table :tag_items do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :tag_items, [:name],      :unique => true


    create_table :recent_views do |t|
      t.references :recent_view_object,                 :null => false
      t.column :o_id,                       :integer,   :null => false
      t.column :created_by_id,              :integer,   :null => false
      t.timestamps
    end
    add_index :recent_views, [:o_id]
    add_index :recent_views, [:created_by_id]
    add_index :recent_views, [:created_at]
    add_index :recent_views, [:recent_view_object_id]


    create_table :activity_streams do |t|
      t.references :activity_stream_type,                   :null => false
      t.references :activity_stream_object,                 :null => false
      t.references :role,                                   :null => true
      t.references :group,                                  :null => true
      t.column :o_id,                           :integer,   :null => false
      t.column :created_by_id,                  :integer,   :null => false
      t.timestamps
    end
    add_index :activity_streams, [:o_id]
    add_index :activity_streams, [:created_by_id]
    add_index :activity_streams, [:role_id]
    add_index :activity_streams, [:group_id]
    add_index :activity_streams, [:created_at]
    add_index :activity_streams, [:activity_stream_object_id]
    add_index :activity_streams, [:activity_stream_type_id]

    create_table :histories do |t|
      t.references :history_type,                       :null => false
      t.references :history_object,                     :null => false
      t.references :history_attribute,                  :null => true
      t.column :o_id,                       :integer,   :null => false
      t.column :related_o_id,               :integer,   :null => true
      t.column :related_history_object_id,  :integer,   :null => true
      t.column :id_to,                      :integer,   :null => true
      t.column :id_from,                    :integer,   :null => true
      t.column :value_from,                 :string,    :limit => 250,  :null => true
      t.column :value_to,                   :string,    :limit => 250,  :null => true
      t.column :created_by_id,              :integer,   :null => false
      t.timestamps
    end
    add_index :histories, [:o_id]
    add_index :histories, [:created_by_id]
    add_index :histories, [:created_at]
    add_index :histories, [:history_object_id]
    add_index :histories, [:history_attribute_id]
    add_index :histories, [:history_type_id]
    add_index :histories, [:id_to]
    add_index :histories, [:id_from]
    add_index :histories, [:value_from]
    add_index :histories, [:value_to]

    create_table :history_types do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :history_types, [:name],     :unique => true

    create_table :history_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.timestamps
    end
    add_index :history_objects, [:name],   :unique => true

    create_table :history_attributes do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.timestamps
    end
    add_index :history_attributes, [:name],   :unique => true


    create_table :settings do |t|
      t.column :title,          :string, :limit => 200,  :null => false
      t.column :name,           :string, :limit => 200,  :null => false
      t.column :area,           :string, :limit => 100,  :null => false
      t.column :description,    :string, :limit => 2000, :null => false
      t.column :options,        :string, :limit => 2000, :null => true
      t.column :state,          :string, :limit => 2000, :null => true
      t.column :state_initial,  :string, :limit => 2000, :null => true
      t.column :frontend,       :boolean,                :null => false
      t.timestamps
    end
    add_index :settings, [:name], :unique => true
    add_index :settings, [:area]
    add_index :settings, [:frontend]

  end
end