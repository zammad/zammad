class AddBcc < ActiveRecord::Migration
  def up
    add_column :ticket_articles, :bcc, :string, limit: 3000
  end
end
