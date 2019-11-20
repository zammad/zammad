class AddAzFieldsToOrganization < ActiveRecord::Migration[5.1]
    def up
  
      # return if it's a new setup
      return if !Setting.find_by(name: 'system_init_done')
  
      add_column :organizations, :azuredevops_organization, :string, limit: 150, null: true
      add_column :organizations, :azuredevops_project, :string, limit: 150, null: true
      add_column :organizations, :azuredevops_area, :string, limit: 250, null: true
      add_column :organizations, :azuredevops_token, :string, limit: 150, null: true

      
      ObjectManager::Attribute.add(
        force:       true,
        object:      'Organization',
        name:        'azuredevops_organization',
        display:     'Azure DevOps Organization',
        data_type:   'input',
        data_option: {
          type:       'text',
          maxlength:  150,
          null:       true,
          item_class: 'formGroup--halfSize',
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
              shown: true,
            },
          },
        },
        to_create:   false,
        to_migrate:  false,
        to_delete:   false,
        position:    1550,
        created_by_id: 1,
        updated_by_id: 1,
      )

      ObjectManager::Attribute.add(
        force:       true,
        object:      'Organization',
        name:        'azuredevops_project',
        display:     'Azure DevOps Project',
        data_type:   'input',
        data_option: {
          type:       'text',
          maxlength:  150,
          null:       true,
          item_class: 'formGroup--halfSize',
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
              shown: true,
            },
          },
        },
        to_create:   false,
        to_migrate:  false,
        to_delete:   false,
        position:    1551,
        created_by_id: 1,
        updated_by_id: 1,
      )
      
      ObjectManager::Attribute.add(
        force:       true,
        object:      'Organization',
        name:        'azuredevops_area',
        display:     'Azure DevOps Area',
        data_type:   'input',
        data_option: {
          type:       'text',
          maxlength:  250,
          null:       true,
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
              shown: true,
            },
          },
        },
        to_create:   false,
        to_migrate:  false,
        to_delete:   false,
        position:    1552,
        created_by_id: 1,
        updated_by_id: 1,
      )

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
                shown: true,
                },
            },
            },
            to_create:   false,
            to_migrate:  false,
            to_delete:   false,
            position:    1553,
            created_by_id: 1,
            updated_by_id: 1,
        )
  
    end
  end
