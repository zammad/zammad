class TicketExtend < ActiveRecord::Migration
  def up
    change_table :tickets do |t|
      t.column :first_response_escal_date,        :timestamp,             :null => true
      t.column :first_response_sla_time,          :timestamp,             :null => true
      t.column :close_time_escal_date,            :timestamp,             :null => true
      t.column :close_time_sla_time,              :timestamp,             :null => true
      t.column :create_article_type_id,           :integer,               :null => true
      t.column :create_article_sender_id,         :integer,               :null => true
      t.column :article_count,                    :integer,               :null => true
    end
    add_index :tickets, [:first_response_escal_date]
    add_index :tickets, [:close_time_escal_date]
    add_index :tickets, [:create_article_type_id]
    add_index :tickets, [:create_article_sender_id]

    tickets = Ticket.all
    tickets.each {|t|
      t.article_count = t.articles.count
      t.create_ticket_article_type_id = t.articles.first.ticket_article_type.id
      t.create_ticket_article_sender_id = t.articles.first.ticket_article_sender.id
      t.save
    }
  end

  def down
  end
end
