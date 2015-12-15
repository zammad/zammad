class CreateExternalCredentials < ActiveRecord::Migration
  def change
    create_table :external_credentials do |t|
      t.string :name
      t.string :credentials, limit: 2500, null: false

      t.timestamps null: false
    end
  end
end
