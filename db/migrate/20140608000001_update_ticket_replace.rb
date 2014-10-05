class UpdateTicketReplace < ActiveRecord::Migration
  def up

    rename_column :tickets, :ticket_priority_id, :priority_id
    rename_column :tickets, :ticket_state_id, :state_id
    rename_column :ticket_articles, :ticket_article_type_id, :type_id
    rename_column :ticket_articles, :ticket_article_sender_id, :sender_id
  end

  def down
  end
end
