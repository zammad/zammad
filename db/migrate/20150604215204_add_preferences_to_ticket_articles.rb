class AddPreferencesToTicketArticles < ActiveRecord::Migration
  def change
    add_column :ticket_articles, :preferences, :text, limit: 500.kilobytes + 1, null: true
  end
end
