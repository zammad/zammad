class UpdateTrigger < ActiveRecord::Migration
  def up

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Trigger.create_or_update(
      name: 'auto reply (on new tickets)',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'create',
        },
        'ticket.state_id' => {
          'operator' => 'is not',
          'value' => Ticket::State.lookup(name: 'closed').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => [
            Ticket::Article::Type.lookup(name: 'email').id,
            Ticket::Article::Type.lookup(name: 'phone').id,
            Ticket::Article::Type.lookup(name: 'web').id,
          ],
        },
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.lookup(name: 'Customer').id,
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>Your request (#{config.ticket_hook}#{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p>Your #{config.product_name} Team</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your inquiry (#{ticket.title})',
        },
      },
      active: false,
      created_by_id: 1,
      updated_by_id: 1,
    )
    Trigger.create_or_update(
      name: 'auto reply (on follow up of tickets)',
      condition: {
        'ticket.action' => {
          'operator' => 'is',
          'value' => 'update',
        },
        'article.sender_id' => {
          'operator' => 'is',
          'value' => Ticket::Article::Sender.lookup(name: 'Customer').id,
        },
        'article.type_id' => {
          'operator' => 'is',
          'value' => [
            Ticket::Article::Type.lookup(name: 'email').id,
            Ticket::Article::Type.lookup(name: 'phone').id,
            Ticket::Article::Type.lookup(name: 'web').id,
          ],
        },
      },
      perform: {
        'notification.email' => {
          'body' => '<p>Your follow up for (#{config.ticket_hook}#{ticket.number}) has been received and will be reviewed by our support staff.<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p>Your #{config.product_name} Team</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Thanks for your follow up (#{ticket.title})',
        },
      },
      active: false,
      created_by_id: 1,
      updated_by_id: 1,
    )

  end

end
