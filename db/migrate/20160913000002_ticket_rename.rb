class TicketRename < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    rename_column :tickets, :first_response, :first_response_at
    rename_column :tickets, :first_response_escal_date, :first_response_escalation_at

    rename_column :tickets, :close_time, :close_at
    rename_column :tickets, :close_time_escal_date, :close_escalation_at
    rename_column :tickets, :close_time_in_min, :close_in_min
    rename_column :tickets, :close_time_diff_in_min, :close_diff_in_min

    rename_column :tickets, :update_time_escal_date, :update_escalation_at
    rename_column :tickets, :update_time_in_min, :update_in_min
    rename_column :tickets, :update_time_diff_in_min, :update_diff_in_min

    rename_column :tickets, :escalation_time, :escalation_at

    rename_column :tickets, :last_contact, :last_contact_at
    rename_column :tickets, :last_contact_agent, :last_contact_agent_at
    rename_column :tickets, :last_contact_customer, :last_contact_customer_at

    remove_column :tickets, :first_response_sla_time
    remove_column :tickets, :close_time_sla_time
    remove_column :tickets, :update_time_sla_time

    overview_role = Role.find_by(name: 'Agent')
    Overview.create_or_update(
      name: 'Escalated',
      link: 'all_escalated',
      prio: 1050,
      role_id: overview_role.id,
      condition: {
        'ticket.escalation_at' => {
          operator: 'within next (relative)',
          value: '10',
          range: 'minute',
        },
      },
      order: {
        by: 'escalation_at',
        direction: 'ASC',
      },
      view: {
        d: %w(title customer group owner escalation_at),
        s: %w(title customer group owner escalation_at),
        m: %w(number title customer group owner escalation_at),
        view_mode_default: 's',
      },
    )

  end
end
