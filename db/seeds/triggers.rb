# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Trigger.create_or_update(
  name:          'auto reply (on new tickets)',
  condition:     {
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
  perform:       {
    'notification.email' => {
      'body'      => '<div>Your request <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by our support staff.</div>
<br/>
<div>To provide additional information, please reply to this email or click on the following link (for initial login, please request a new password):
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>Your #{config.product_name} Team</div>
<br/>
<div><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></div>',
      'recipient' => 'article_last_sender',
      'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  active:        true,
  created_by_id: 1,
  updated_by_id: 1,
)
Trigger.create_or_update(
  name:          'auto reply (on follow-up of tickets)',
  condition:     {
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
  perform:       {
    'notification.email' => {
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
      'subject'   => 'Thanks for your follow-up (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  active:        false,
  created_by_id: 1,
  updated_by_id: 1,
)

Trigger.create_or_update(
  name:          'customer notification (on owner change)',
  condition:     {
    'ticket.owner_id' => {
      'operator'         => 'has changed',
      'pre_condition'    => 'current_user.id',
      'value'            => '',
      'value_completion' => '',
    }
  },
  perform:       {
    'notification.email' => {
      'body'      => '<p>The owner of ticket (Ticket##{ticket.number}) has changed and is now "#{ticket.owner.firstname} #{ticket.owner.lastname}".<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="https://zammad.com">Zammad</a>, your customer support system</i></p>',
      'recipient' => 'ticket_customer',
      'subject'   => 'Owner has changed (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  active:        false,
  created_by_id: 1,
  updated_by_id: 1,
)
