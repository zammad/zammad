class SettingAddTicketAutoAssignment < ActiveRecord::Migration[5.1]
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_if_not_exists(
      title: 'Auto Assigment',
      name: 'ticket_auto_assignment',
      area: 'Web::Base',
      description: 'Enable ticket auto assignment.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ticket_auto_assignment',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      preferences: {
        authentication: true,
        permission: ['admin.ticket_auto_assignment'],
      },
      state: false,
      frontend: true
    )
    Setting.create_if_not_exists(
      title: 'Time Accounting Selector',
      name: 'ticket_auto_assignment_selector',
      area: 'Web::Base',
      description: 'Enable auto assignment for following matching tickets.',
      options: {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission: ['admin.ticket_auto_assignment'],
      },
      state: { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } },
      frontend: true
    )
  end
end
