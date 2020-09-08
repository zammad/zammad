class CreateWebhooks < ActiveRecord::Migration[5.2]
  def change
    create_table :webhooks do |t|
      t.string :url
      t.boolean :active

      t.timestamps
    end
  end
end
