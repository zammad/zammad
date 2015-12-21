class UpdateTicketPreferences < ActiveRecord::Migration
  def up
    add_column :tickets, :preferences, :text, limit: 500.kilobytes + 1, null: true
  end
end
