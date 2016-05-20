
class EmailTicketCc < ActiveRecord::Migration
  def up
    ObjectManager::Attribute.add(
      force: true,
      object: 'Ticket',
      name: 'cc',
      display: 'Cc',
      data_type: 'input',
      data_option: {
        type: 'text',
        maxlength: 1000,
        null: true,
      },
      editable: false,
      active: true,
      screens: {
        create_top: {
          Agent: {
            null: true,
          },
        },
        create_middle: {},
        edit: {}
      },
      to_create: false,
      to_migrate: false,
      to_delete: false,
      position: 11,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

end
