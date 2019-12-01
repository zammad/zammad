class PredefinedRoles < ActiveRecord::Migration[5.1]
    def up

      # return if it's a new setup
      return if !Setting.find_by(name: 'system_init_done')

      agent = Role.find_by(name: 'Agent')
      agent.permission_grant('knowledge_base.editor')
      RoleGroup.create_if_not_exists(role: agent, group: Group.find_by(name: 'Incoming'))

      Role.create_if_not_exists(
        name:              'Connector',
        note:              '',
        preferences:       {
          not: %w[Agent Admin Customer],
        },
        default_at_signup: false,
        updated_by_id:     1,
        created_by_id:     1
      )

      connector = Role.find_by(name: 'Connector')
      connector.permission_grant('ticket.agent')


    end
end
