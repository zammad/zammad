class HideAzTokenFieldInUi < ActiveRecord::Migration[5.1]
    def up
  
      return if !Setting.find_by(name: 'system_init_done')

      ObjectManager::Attribute.add(
            force:       true,
            object:      'Organization',
            name:        'azuredevops_token',
            display:     'Azure DevOps Token',
            data_type:   'input',
            data_option: {
            type:       'password',
            maxlength:  150,
            null:       false,
            permission: ['admin.organization'],
            },
            editable:    false,
            active:      true,
            screens:     {
            edit: {
                '-all-' => {
                null: false,
                },
            },
            view: {
                '-all-' => {
                shown: false,
                },
            },
            },
            to_create:   false,
            to_migrate:  false,
            to_delete:   false,
            position:    1553,
            created_by_id: 1,
            updated_by_id: 1
      )
    end
  end
