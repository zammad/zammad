# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddTicketApprovalAttributes < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    create_columns
    add_approver_attribute
    add_approval_state_attribute
    add_approval_trigger
    add_approval_state_note_trigger
    add_approval_state_workflow
    add_waiting_for_approval_overview
  end

  private

  def create_columns
    change_table :tickets, bulk: true do |t|
      t.column :approver,       :string, limit: 100,  null: true if !column_exists?(:tickets, :approver)
      t.column :approval_state, :string, limit: 100,  null: true if !column_exists?(:tickets, :approval_state)
    end

    Ticket.reset_column_information
  end

  def add_approver_attribute
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'approver',
      display:     'Approver',
      data_type:   'select',
      data_option: {
        default:    '',
        relation:   'User',
        nulloption: true,
        multiple:   false,
        null:       true,
        translate:  false,
        permission: ['ticket.agent', 'ticket.customer'],
      },
      editable:    true,
      active:      true,
      screens:     {
        create_middle: {
          '-all-' => {
            null: true,
          },
        },
        edit:          {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1500,
    )
  end

  def add_approval_state_attribute
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'approval_state',
      display:     'Approval State',
      data_type:   'select',
      data_option: {
        default:    'not_requested',
        options:    {
          'not_requested' => 'Not requested',
          'pending'       => 'Pending approval',
          'approved'      => 'Approved',
          'rejected'      => 'Rejected',
        },
        nulloption: false,
        multiple:   false,
        null:       true,
        translate:  true,
        permission: ['ticket.agent', 'ticket.customer'],
      },
      editable:    true,
      active:      true,
      screens:     {
        create_middle: {
          'ticket.agent' => {
            null: true,
          },
        },
        edit:          {
          '-all-' => {
            null: true,
          },
        },
      },
      to_create:   false,
      to_migrate:  false,
      to_delete:   false,
      position:    1510,
    )
  end

  def add_approval_trigger
    Trigger.create_or_update(
      name:                     'approval request (notify approver)',
      condition:                {
        'ticket.action'   => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.approver' => {
          'operator'      => 'is not',
          'pre_condition' => 'not_set',
          'value'         => '',
        },
      },
      perform:                  {
        'notification.email' => {
          # rubocop:disable Lint/InterpolationCheck
          'body'      => '<div>Hello,</div>
<br/>
<div>#{ticket.customer.firstname} #{ticket.customer.lastname} has created the request <b>(#{config.ticket_hook}#{ticket.number})</b> and asks for your approval.</div>
<br/>
<div>Subject: #{ticket.title}</div>
<br/>
<div>Please review the request and approve or reject it here:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>Your #{config.product_name} Team</div>',
          # rubocop:enable Lint/InterpolationCheck
          'recipient' => 'ticket_custom_field_approver',
          'subject'   => 'Approval requested for #{ticket.title}', # rubocop:disable Lint/InterpolationCheck
        },
      },
      activator:                'action',
      execution_condition_mode: 'selective',
      active:                   true,
      created_by_id:            1,
      updated_by_id:            1,
    )
  end

  def add_approval_state_note_trigger
    Trigger.create_or_update(
      name:                     'approval decision (add note to timeline)',
      condition:                {
        'ticket.action'         => {
          'operator' => 'is',
          'value'    => 'update',
        },
        'ticket.approval_state' => {
          'operator' => 'has changed',
        },
      },
      perform:                  {
        'article.note' => {
          # rubocop:disable Lint/InterpolationCheck
          'subject'  => 'Approval state changed',
          'body'     => 'The approval state was changed to <b>#{ticket.approval_state}</b> by #{user.firstname} #{user.lastname}.',
          # rubocop:enable Lint/InterpolationCheck
          'internal' => 'false',
        },
      },
      activator:                'action',
      execution_condition_mode: 'selective',
      active:                   true,
      created_by_id:            1,
      updated_by_id:            1,
    )
  end

  def add_approval_state_workflow
    CoreWorkflow.create_if_not_exists(
      name:            'base - restrict ticket approval state to approver',
      object:          'Ticket',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::TicketApprovalState',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::TicketApprovalState']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end

  def add_waiting_for_approval_overview
    role = Role.find_by(name: 'Customer')
    return if role.blank?

    Overview.create_if_not_exists(
      name:          'Waiting for my Approval',
      link:          'waiting_for_my_approval',
      prio:          1150,
      role_ids:      [role.id],
      condition:     {
        'ticket.state_id'       => {
          operator: 'is',
          value:    Ticket::State.by_category_ids(:viewable),
        },
        'ticket.approver'       => {
          operator:      'is',
          pre_condition: 'current_user.id',
          value:         '',
        },
        'ticket.approval_state' => {
          operator: 'is',
          value:    'pending',
        },
      },
      order:         {
        by:        'created_at',
        direction: 'DESC',
      },
      view:          {
        d:                 %w[title customer state created_at],
        s:                 %w[number title state created_at],
        m:                 %w[number title state created_at],
        view_mode_default: 's',
      },
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
