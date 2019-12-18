class AddSecurityPermissionToConnectorRole < ActiveRecord::Migration[5.1]
    def up
        
        return if !Setting.find_by(name: 'system_init_done')
        
        connectorRole = Role.find_by(name: 'Connector')
        connectorRole.permission_grant('admin.security')
        connectorRole.save!
    end
end
