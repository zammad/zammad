class TicketCounter < ActiveRecord::Migration
  def up
    create_table :ticket_counters do |t|
      t.column :content,              :string, :limit => 100, :null => false
      t.column :generator,            :string, :limit => 100, :null => false
    end
    add_index :ticket_counters, [:generator], :unique => true
  end

  def down
  end
end
