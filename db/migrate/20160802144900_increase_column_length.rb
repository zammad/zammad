class IncreaseColumnLength < ActiveRecord::Migration
  def change
    change_table(:translations) do |t|
      # test
      t.change   :source,         :string, limit: 500, null: false
      t.change   :target,         :string, limit: 500, null: false
      t.change   :target_initial, :string, limit: 500, null: false
    end
  end
end
