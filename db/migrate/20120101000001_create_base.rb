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
      t.column :preferences,    :string, :limit => 8000,:null => true
      t.column :updated_by_id,  :integer,               :null => false
      t.column :created_by_id,  :integer,               :null => false
      t.timestamps
    end
    add_index :users, [:login], :unique => true
    add_index :users, [:email]
#    add_index :users, [:email], :unique => true
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

  end
end

