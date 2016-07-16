class UpdateSettingEmail < ActiveRecord::Migration
  def up
    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    Setting.create_or_update(
      title: 'Ticket Subject Size',
      name: 'ticket_subject_size',
      area: 'Email::Base',
      description: 'Max size of the subjects in an email reply.',
      options: {
        form: [
          {
            display: '',
            null: false,
            name: 'ticket_subject_size',
            tag: 'input',
          },
        ],
      },
      state: '110',
      frontend: false
    )
    Setting.create_or_update(
      title: 'Ticket Subject Reply',
      name: 'ticket_subject_re',
      area: 'Email::Base',
      description: 'The text at the beginning of the subject in an email reply, e.g. RE, AW, or AS.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'ticket_subject_re',
            tag: 'input',
          },
        ],
      },
      state: 'RE',
      frontend: false
    )

    Trigger.create_or_update(
      name: 'customer notification (on owner change)',
      condition: {
        'ticket.owner_id' => {
          'operator' => 'has changed',
          'pre_condition' => 'current_user.id',
          'value' => '',
          'value_completion' => '',
        }
      },
      perform: {
        'notification.email' => {
          'body' => '<p>The owner of ticket (Ticket##{ticket.number}) has changed and is now "#{ticket.owner.firstname} #{ticket.owner.lastname}".<p>
<br/>
<p>To provide additional information, please reply to this email or click on the following link:
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}</a>
</p>
<br/>
<p><i><a href="http://zammad.com">Zammad</a>, your customer support system</i></p>',
          'recipient' => 'ticket_customer',
          'subject' => 'Owner has changed (#{ticket.title})',
        },
      },
      active: false,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
