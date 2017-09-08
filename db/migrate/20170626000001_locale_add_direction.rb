class LocaleAddDirection < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :locales, :dir, :string, limit: 9, null: false, default: 'ltr'
  end
end
