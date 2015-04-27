class CreateLocale < ActiveRecord::Migration
  def up
    create_table :locales do |t|
      t.string  :locale,               limit: 20,  null: false
      t.string  :alias,                limit: 20,  null: true
      t.string  :name,                 limit: 255, null: false
      t.boolean :active,                              null: false, default: true

      t.timestamps null: false
    end

    add_index :locales, [:locale], unique: true
    add_index :locales, [:name], unique: true

    Locale.create(
      locale: 'en-us',
      alias: 'en',
      name: 'English (United States)',
    )
  end

  def down
  end

end