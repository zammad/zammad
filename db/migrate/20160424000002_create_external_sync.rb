class CreateExternalSync < ActiveRecord::Migration
  def up
    create_table :external_syncs do |t|
      t.string  :source,                 limit: 100,  null: false
      t.string  :source_id,              limit: 200,  null: false
      t.string  :object,                 limit: 100,  null: false
      t.integer :o_id,                                null: false
      t.text    :last_payload,           limit: 500.kilobytes + 1, null: true
      t.timestamps null: false
    end
    add_index :external_syncs, [:source, :source_id], unique: true
    add_index :external_syncs, [:source, :source_id, :object, :o_id], name: 'index_external_syncs_on_source_and_source_id_and_object_o_id'
    add_index :external_syncs, [:object, :o_id]
  end
end
