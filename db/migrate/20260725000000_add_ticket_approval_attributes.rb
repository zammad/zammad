# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddTicketApprovalAttributes < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    add_approver_attribute
    add_approval_state_attribute
    add_approval_trigger
  end

  private

  def add_approver_attribute
    ObjectManager::Attribute.add(
      force:       true,
      object:      'Ticket',
      name:        'approver_id',
      display:     __('Approver'),
      data_type:   'user_autocompletion',
      data_option: {
        relation:       'User',
        autocapitalize: false,
        multiple:       false,
        guess:          false,
        null:           true,
        limit:          200,
        placeholder:    __('Enter the approver who should approve this request'),
        minLengt:       2,
        translate:      false,
        permission:     ['ticket.agent', 'ticket.customer'],
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
      display:     __('Approval State'),
      data_type:   'select',
      data_option: {
        default:    'not_requested',
        options:    {
          'not_requested' => __('Not requested'),
          'pending'       => __('Pending approval'),
          'approved'      => __('Approved'),
          'rejected'      => __('Rejected'),
        },
        nulloption: false,
        multiple:   false,
        null:       true,
        translate:  true,
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
          'ticket.agent' => {
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
        'ticket.action'      => {
          'operator' => 'is',
          'value'    => 'create',
        },
        'ticket.approver_id' => {
          'operator' => 'is set',
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
          'recipient' => 'ticket_custom_field_approver_id',
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
end
