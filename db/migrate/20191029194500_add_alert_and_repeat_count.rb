class AddAlertAndRepeatCount < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :tickets, :alert, :string, limit: 999, null: true
    add_column :tickets, :repeat_count, :integer, null: true
    
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'alert',
      display:     'alert',
      data_type:   'input',
      data_option: {
        default:    '',  
        type:      'text',
        maxlength: 2000,
        null:      true,
        translate: false,
      },
      editable:    false,
      active:      true, 
      screens: {
        create_middle: {},
        edit: {},        
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    101,  
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'repeat_count',
      display:     'repeat count',  
      data_type:   'integer',
      data_option: {
        default:    0, 
        maxlength: 150,
        null:      true,
        note:      'The number of the same alerts fired',
        min:       0,
        max:       999_999_999,
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {},
        edit: {
         'ticket.customer' => {
            shown: true,                           
          },
           'ticket.agent' => {
             shown: true,
             },
         },    
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    102,
      created_by_id: 1,
      updated_by_id: 1,
    )
    
  end
end
