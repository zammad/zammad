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
      'body'      => '<div>Your request <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by support personel.</div>
<br/>
<div>To provide additional information, please reply to this email or click on the link (for initial login, please request a new password):
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>VIAcode Incident Management System</div>
<br/>
<div><p>Let VIAcode deal with these alerts & manage your Azure cloud operation for free; <a href="https://www.viacode.com/services/azure-managed-services/?utm_source=product&utm_medium=email&utm_campaign=VIMS&utm_content=passwordchangeemail">activate here</a></p></div>',
      'recipient' => 'article_last_sender',
      'subject'   => 'Thanks for your inquiry (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  active:        true,
  created_by_id: 1,
  updated_by_id: 1,
)
Trigger.create_or_update(
  name:          'auto reply (on follow up of tickets)',
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
      'body'      => '<div>Your follow up for <b>(#{config.ticket_hook}#{ticket.number})</b> has been received and will be reviewed by support personel.</div>
<br/>
<div>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</div>
<br/>
<div>VIAcode Incident Management System</div>
<br/>
<div><p>Let VIAcode deal with these alerts & manage your Azure cloud operation for free; <a href="https://www.viacode.com/services/azure-managed-services/?utm_source=product&utm_medium=email&utm_campaign=VIMS&utm_content=passwordchangeemail">activate here</a></p></div>',
      'recipient' => 'article_last_sender',
      'subject'   => 'Thanks for your follow up (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
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
<div>VIAcode Incident Management System</div>
</br>
<div><p>Let VIAcode deal with these alerts & manage your Azure cloud operation for free; <a href="https://www.viacode.com/services/azure-managed-services/?utm_source=product&utm_medium=email&utm_campaign=VIMS&utm_content=passwordchangeemail">activate here</a></p></div>',
      'recipient' => 'ticket_customer',
      'subject'   => 'Owner has changed (#{ticket.title})', # rubocop:disable Lint/InterpolationCheck
    },
  },
  active:        false,
  created_by_id: 1,
  updated_by_id: 1,
)
