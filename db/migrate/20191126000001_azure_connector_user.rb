class AzureConnectorUser < ActiveRecord::Migration[5.1]
    def up
        
        return if !Setting.find_by(name: 'system_init_done')
        
        User.create_if_not_exists(
            id:              2,
            login:           'connector',
            firstname:       'Azure Monitor',
            lastname:        'Connector',
            email:           '',
            password:        'connector',
            active:          false,
            roles:           [ Role.find_by(name: 'Connector') ],
            organization_id:  Organization.find_by(name: 'Customer').id,
            updated_by_id:   1,
            created_by_id:   1
            )
    end
end
