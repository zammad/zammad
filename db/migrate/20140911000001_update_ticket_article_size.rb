class UpdateTicketArticleSize < ActiveRecord::Migration
  def up
    change_column :ticket_articles, :body, :text, limit: 4.megabytes + 1
  end

  def down
  end
end
