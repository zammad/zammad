class CreateGuestTicketAttachments < ActiveRecord::Migration[7.0]
  def change
    create_table :guest_ticket_attachments do |t|
      t.references :guest_ticket, null: false, foreign_key: true
      t.string :original_filename, null: false

      t.timestamps
    end

    add_index :guest_ticket_attachments, :guest_ticket_id
  end
end
