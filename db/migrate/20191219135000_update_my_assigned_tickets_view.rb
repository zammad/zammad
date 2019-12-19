class UpdateMyAssignedTicketsView < ActiveRecord::Migration[5.1]
    def up
        
        return if !Setting.find_by(name: 'system_init_done')

        overview_role = Role.find_by(name: 'Agent')
    
        Overview.create_or_update(
        name:      'My assigned Tickets',
        link:      'my_assigned',
        prio:      1000,
        role_ids:  [overview_role.id],
        condition: {
            'ticket.state_id' => {
            operator: 'is',
            value:    Ticket::State.by_category(:open).pluck(:id),
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
    end
end
