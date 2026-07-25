# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Trigger.create_or_update(
  name:                     'auto reply (on new tickets)',
  condition:                {
    'ticket.action'     => {
      'operator' => 'is',
      'value'    => 'create',
    },
    'ticket.state_id'   => {
      'operator' => 'is not',
      'value'    => Ticket::State.by_category(:closed).first.id,
    },
    'article.type_id'   => {
      'operator' => 'is',
      'value'    => [
        Ticket::Article::Type.lookup(name: 'email').id,
        Ticket::Article::Type.lookup(name: 'phone').id,
        Ticket::Article::Type.lookup(name: 'web').id,
      ],
    },
    'article.sender_id' => {
      'operator' => 'is',
      'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
    },
  },
  perform:                  {
    'notification.email' => {
      # rubocop:disable Lint/InterpolationCheck
      'body'      => '<div>Your request <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
<br/>
<div>To provide additional information, please reply to this email or click on the following link (for initial login, please request a new password):
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>Your #{config.product_name} Team</div>
<br/>
<div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
      # rubocop:enable Lint/InterpolationCheck
      'recipient' => 'article_last_sender',
      'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   true,
  created_by_id:            1,
  updated_by_id:            1,
)
Trigger.create_or_update(
  name:                     'auto reply (on follow-up of tickets)',
  condition:                {
    'ticket.action'     => {
      'operator' => 'is',
      'value'    => 'update',
    },
    'article.sender_id' => {
      'operator' => 'is',
      'value'    => Ticket::Article::Sender.lookup(name: 'Customer').id,
    },
    'article.type_id'   => {
      'operator' => 'is',
      'value'    => [
        Ticket::Article::Type.lookup(name: 'email').id,
        Ticket::Article::Type.lookup(name: 'phone').id,
        Ticket::Article::Type.lookup(name: 'web').id,
      ],
    },
  },
  perform:                  {
    'notification.email' => {
      # rubocop:disable Lint/InterpolationCheck
      'body'      => '<div>Your follow-up for <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
<br/>
<div>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>Your #{config.product_name} Team</div>
<br/>
<div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
      'recipient' => 'article_last_sender',
      'subject'   => 'Thanks for your follow-up (#{ticket.title})',
      # rubocop:enable Lint/InterpolationCheck
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   false,
  created_by_id:            1,
  updated_by_id:            1,
)

Trigger.create_or_update(
  name:                     'customer notification (on owner change)',
  condition:                {
    'ticket.owner_id' => {
      'operator'         => 'has changed',
      'pre_condition'    => 'current_user.id',
      'value'            => '',
      'value_completion' => '',
    }
  },
  perform:                  {
    'notification.email' => {
      # rubocop:disable Lint/InterpolationCheck
      'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed and is now "#{ticket.owner.firstname} #{ticket.owner.lastname}".<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></p>',
      'recipient' => 'ticket_customer',
      'subject'   => 'Owner has changed (#{ticket.title})',
      # rubocop:enable Lint/InterpolationCheck
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   false,
  created_by_id:            1,
  updated_by_id:            1,
)

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
      # rubocop:disable Lint/InterpolationCheck, Zammad/DetectTranslatableString
      'subject'  => 'Approval state changed',
      'body'     => 'The approval state was changed to <b>#{ticket.approval_state}</b> by #{user.firstname} #{user.lastname}.',
      # rubocop:enable Lint/InterpolationCheck, Zammad/DetectTranslatableString
      'internal' => 'false',
    },
  },
  activator:                'action',
  execution_condition_mode: 'selective',
  active:                   true,
  created_by_id:            1,
  updated_by_id:            1,
)
