class UpdateTranslation < ActiveRecord::Migration
  def up
    add_column :translations, :format, :string, limit: 20, null: false, default: 'string'
  end

  def down
  end
end
