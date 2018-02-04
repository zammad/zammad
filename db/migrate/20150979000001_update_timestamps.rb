class UpdateTimestamps < ActiveRecord::Migration[4.2]
  def up
    # get all models
    Models.all.each_value do |value|
      next if !value
      next if !value[:attributes]
      if value[:attributes].include?('changed_at')
        ActiveRecord::Migration.change_column value[:table].to_sym, :changed_at, :datetime, null: false
      end
      if value[:attributes].include?('created_at')
        ActiveRecord::Migration.change_column value[:table].to_sym, :created_at, :datetime, null: false
      end
    end
  end
end
