class UpdateTicketArticle < ActiveRecord::Migration
  def up
    add_column :ticket_articles, :content_type,  :string, :limit => 20,  :null => false, :default => 'text/plain'
  end

  def down
  end
end
