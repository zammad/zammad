class AddDefaultOrganizations < ActiveRecord::Migration[5.1]
    def up

      # return if it's a new setup
      return if !Setting.find_by(name: 'system_init_done')

      Organization.create_if_not_exists(
        name: 'Customer',
        created_by_id: 1,
        updated_by_id: 1
      )

      Organization.create_if_not_exists(
        name: 'Default SRE Provider',
        created_by_id: 1,
        updated_by_id: 1
      )

    end
end
