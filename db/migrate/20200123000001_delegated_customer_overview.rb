class DelegatedCustomerOverview < ActiveRecord::Migration[5.1]
    def up
        
        return if !Setting.find_by(name: 'system_init_done')
        
        overview_role = Role.find_by(name: 'Customer')

        Overview.create_or_update(
            name:      'My delegated Tickets',
            link:      'my_delegated_tickets',
            prio:      1090,
            role_ids:  [overview_role.id],
            condition: {
              'ticket.state_id' => {
                operator: 'is',
                value:    Ticket::State.by_category(:delegated).pluck(:id),
              },
              'ticket.owner_id' => {
                operator:      'is',
                pre_condition: 'current_user.id',
              },
            },
            order:     {
              by:        'created_at',
              direction: 'ASC',
            },
            view:      {
              d:                 %w[title customer group created_at],
              s:                 %w[title customer group created_at],
              m:                 %w[number title customer group created_at],
              view_mode_default: 's',
            },
            updated_by_id: 1,
            created_by_id: 1,
          )

        Cache.clear
          
    end
end
