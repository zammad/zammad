class TokenPersistent < ActiveRecord::Migration
  def up
    add_column :tokens, :persistent, :boolean
  end

  def down
  end
end
