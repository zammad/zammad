class CreateGuestTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :guest_tickets do |t|
      t.string :reference_number, null: false, unique: true
      t.string :email, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.integer :ticket_type, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.string :aasm_state, default: 'pending'
      t.jsonb :specific_data, default: {}
      t.references :ticket, foreign_key: true, optional: true
      t.datetime :submitted_at
      t.datetime :assigned_at
      t.datetime :resolved_at
      t.datetime :aasm_state_updated_at

      t.timestamps
    end

    add_index :guest_tickets, :reference_number
    add_index :guest_tickets, :email
    add_index :guest_tickets, :ticket_type
    add_index :guest_tickets, :status
    add_index :guest_tickets, :aasm_state
    add_index :guest_tickets, :created_at
  end
end
