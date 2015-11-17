class UpdateHistory < ActiveRecord::Migration
  def up
    remove_index :histories, [:value_from]
    remove_index :histories, [:value_to]
    change_table(:histories) do |t|
      t.change :value_from, :text, limit: 500, null: true
      t.change :value_to, :text, limit: 500, null: true
    end
    add_index :histories, [:value_from], length: 255
    add_index :histories, [:value_to], length: 255
  end
end
