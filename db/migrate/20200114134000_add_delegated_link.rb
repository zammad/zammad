class AddDelegatedLink < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :tickets, :delegated_link, :string, limit: 250, null: false, default: 'https://pornhub.com'

    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'delegated_link',
      display:     'Delegated Request Link',
      data_type:   'input',
      data_option: {
        type:       'url',
        default:    'https://pornhub.com',
        null:      false,
        maxlength: 250,
        note:      'Delegated Request Link',
      },
      editable:    false,
      active:      true,
      screens:     {
        create_middle: {},
        edit         : {},
        view         : {
          '-all-' => {
            shown: true,
                     },
                        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    103,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end
end
