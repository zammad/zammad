class CreateTicket < ActiveRecord::Migration
  def up
    create_table :ticket_state_types do |t|
      t.column :name,                 :string, :limit => 250, :null => false
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_state_types, [:name], :unique => true

    create_table :ticket_states do |t|
      t.references :ticket_state_type, :null => false
      t.column :name,                 :string, :limit => 250, :null => false
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :active,               :boolean,               :null => false, :default => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_states, [:name], :unique => true

    create_table :ticket_priorities do |t|
      t.column :name,                 :string, :limit => 250, :null => false
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :active,               :boolean,               :null => false, :default => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_priorities, [:name], :unique => true

    create_table :tickets do |t|
      t.references :group,                                      :null => false
      t.references :ticket_priority,                            :null => false
      t.references :ticket_state,                               :null => false
      t.references :organization,                               :null => true
      t.column :number,                :string,  :limit => 60,  :null => false
      t.column :title,                 :string,  :limit => 250, :null => false
      t.column :owner_id,              :integer,                :null => false
      t.column :customer_id,           :integer,                :null => false
      t.column :note,                  :string,  :limit => 250, :null => true
      t.column :first_response,        :timestamp,              :null => true
      t.column :last_contact,          :timestamp,              :null => true
      t.column :last_contact_agent,    :timestamp,              :null => true
      t.column :last_contact_customer, :timestamp,              :null => true
      t.column :close_time,            :timestamp,              :null => true
      t.column :updated_by_id,         :integer,                :null => false
      t.column :created_by_id,         :integer,                :null => false
      t.timestamps
    end
    add_index :tickets, [:ticket_state_id]
    add_index :tickets, [:ticket_priority_id]
    add_index :tickets, [:group_id]
    add_index :tickets, [:owner_id]
    add_index :tickets, [:customer_id]
    add_index :tickets, [:number], :unique => true
    add_index :tickets, [:title]
    add_index :tickets, [:created_at]
    add_index :tickets, [:first_response]
    add_index :tickets, [:last_contact]
    add_index :tickets, [:last_contact_agent]
    add_index :tickets, [:last_contact_customer]
    add_index :tickets, [:close_time]
    add_index :tickets, [:created_by_id]

    create_table :ticket_flags do |t|
      t.references :tickets,                            :null => false
      t.column :key,            :string, :limit => 50,  :null => false
      t.column :value,          :string, :limit => 50,  :null => true
      t.column :created_by_id,  :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_flags, [:tickets_id, :created_by_id]
    add_index :ticket_flags, [:tickets_id, :key]
    add_index :ticket_flags, [:tickets_id]
    add_index :ticket_flags, [:created_by_id]

    create_table :ticket_time_accounting do |t|
      t.references :tickets,                                            :null => false
      t.references :ticket_articles,                                    :null => true
      t.column :time_unit,      :decimal, :precision => 6, :scale => 2, :null => false
      t.column :created_by_id,  :integer,                               :null => false
      t.timestamps
    end
    add_index :ticket_time_accounting, [:tickets_id]
    add_index :ticket_time_accounting, [:ticket_articles_id]
    add_index :ticket_time_accounting, [:created_by_id]

    create_table :ticket_article_types do |t|
      t.column :name,                 :string, :limit => 250, :null => false
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :communication,        :boolean,               :null => false
      t.column :active,               :boolean,               :null => false, :default => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_article_types, [:name], :unique => true

    create_table :ticket_article_senders do |t|
      t.column :name,                 :string, :limit => 250, :null => false
      t.column :note,                 :string, :limit => 250, :null => true
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,               :null => false
      t.timestamps
    end
    add_index :ticket_article_senders, [:name], :unique => true

    create_table :ticket_articles do |t|
      t.references :ticket,                                 :null => false
      t.references :ticket_article_type,                    :null => false
      t.references :ticket_article_sender,                  :null => false
      t.column :from,                 :string, :limit => 3000,    :null => true
      t.column :to,                   :string, :limit => 3000,    :null => true
      t.column :cc,                   :string, :limit => 3000,    :null => true
      t.column :subject,              :string, :limit => 3000,    :null => true
#      t.column :reply_to,             :string, :limit => 3000,    :null => true
      t.column :message_id,           :string, :limit => 3000,    :null => true
      t.column :message_id_md5,       :string, :limit => 32,      :null => true
      t.column :in_reply_to,          :string, :limit => 3000,    :null => true
      t.column :references,           :string, :limit => 3200,    :null => true
      t.column :body,                 :text,                      :null => true
      t.column :internal,             :boolean,                   :null => false, :default => false
      t.column :updated_by_id,        :integer,               :null => false
      t.column :created_by_id,        :integer,                   :null => false
      t.timestamps
    end
    add_index :ticket_articles, [:ticket_id]
    add_index :ticket_articles, [:message_id_md5]
    add_index :ticket_articles, [:message_id_md5, :ticket_article_type_id], :name => 'index_ticket_articles_message_id_md5_type_id'
    add_index :ticket_articles, [:created_by_id]
    add_index :ticket_articles, [:internal]
    add_index :ticket_articles, [:ticket_article_type_id]
    add_index :ticket_articles, [:ticket_article_sender_id]

    create_table :ticket_article_flags do |t|
      t.references :ticket_articles,                        :null => false
      t.column :key,                 :string, :limit => 50, :null => false
      t.column :value,               :string, :limit => 50, :null => true
      t.column :created_by_id,       :integer,              :null => false
      t.timestamps
    end
    add_index :ticket_article_flags, [:ticket_articles_id, :created_by_id], :name => 'index_ticket_article_flags_on_articles_id_and_created_by_id'
    add_index :ticket_article_flags, [:ticket_articles_id, :key]
    add_index :ticket_article_flags, [:ticket_articles_id]
    add_index :ticket_article_flags, [:created_by_id]

    create_table :ticket_counters do |t|
      t.column :content,              :string, :limit => 100, :null => false
      t.column :generator,            :string, :limit => 100, :null => false
    end
    add_index :ticket_counters, [:generator], :unique => true

    create_table :overviews do |t|
      t.references :user,                                      :null => true
      t.references :role,                                      :null => false
      t.column :name,                 :string,  :limit => 250,  :null => false
      t.column :meta,                 :string,  :limit => 1000, :null => false
      t.column :condition,            :string,  :limit => 2500, :null => false
      t.column :order,                :string,  :limit => 2500, :null => false
      t.column :group_by,             :string,  :limit => 250,  :null => true
      t.column :organization_shared,  :boolean,                 :null => false, :default => false
      t.column :view,                 :string,  :limit => 1000, :null => false
      t.column :active,               :boolean,                 :null => false, :default => true
      t.column :updated_by_id,        :integer,                 :null => false
      t.column :created_by_id,        :integer,                 :null => false
      t.timestamps
    end
    add_index :overviews, [:user_id]
    add_index :overviews, [:name]

    create_table :overviews_groups, :id => false do |t|
      t.integer :overview_id
      t.integer :group_id
    end
    add_index :overviews_groups, [:overview_id]
    add_index :overviews_groups, [:group_id]

    create_table :triggers do |t|
      t.column :name,   :string, :limit => 250, :null => false
      t.column :key,    :string, :limit => 250, :null => false
      t.column :value,  :string, :limit => 250, :null => false
    end
    add_index :triggers, [:name]
    add_index :triggers, [:key]
    add_index :triggers, [:value]

    create_table :notifications do |t|
      t.column :subject,      :string, :limit => 250,   :null => false
      t.column :body,         :string, :limit => 8000,  :null => false
      t.column :content_type, :string, :limit => 250,   :null => false
      t.column :active,       :boolean,                 :null => false, :default => true
      t.column :note,         :string, :limit => 250,   :null => true
      t.timestamps
    end

    create_table :link_types do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.column :active,       :boolean,                 :null => false, :default => true
      t.timestamps
    end
    add_index :link_types, [:name],     :unique => true

    create_table :link_objects do |t|
      t.column :name,         :string, :limit => 250,   :null => false
      t.column :note,         :string, :limit => 250,   :null => true
      t.column :active,       :boolean,                 :null => false, :default => true
      t.timestamps
    end
    add_index :link_objects, [:name],   :unique => true

    create_table :links do |t|
      t.references :link_type,                                        :null => false
      t.column :link_object_source_id,        :integer,               :null => false
      t.column :link_object_source_value,     :integer,               :null => false
      t.column :link_object_target_id,        :integer,               :null => false
      t.column :link_object_target_value,     :integer,               :null => false
      t.timestamps
    end
    add_index :links, [:link_object_source_id, :link_object_source_value, :link_object_target_id, :link_object_target_value, :link_type_id], :unique => true, :name => 'links_uniq_total'
  end

  def self.down
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
