# encoding: utf-8

class Observer::Ticket::Notification::BackgroundJob
  def initialize(params, via_web = false)
    @p = params
    @via_web = via_web
  end

  def perform
    ticket = Ticket.find(@p[:ticket_id])
    if @p[:article_id]
      article = Ticket::Article.find(@p[:article_id])
    end

    # find recipients
    recipients_and_channels = []

=begin
    # group of agents to work on
    if data[:recipient] == 'group'
      recipients = ticket.agent_of_group()

    # owner
    elsif data[:recipient] == 'owner'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      end

    # customer
    elsif data[:recipient] == 'customer'
      if ticket.customer_id != 1
        # temporarily disabled
        #        recipients.push ticket.customer
      end

    # owner or group of agents to work on
    elsif data[:recipient] == 'to_work_on'
      if ticket.owner_id != 1
        recipients.push ticket.owner
      else
        recipients = ticket.agent_of_group()
      end
    end
=end

    # loop through all users
    possible_recipients = ticket.agent_of_group
    if ticket.owner_id == 1
      possible_recipients.push ticket.owner
    end
    already_checked_recipient_ids = {}
    possible_recipients.each {|user|
      next if already_checked_recipient_ids[user.id]
      already_checked_recipient_ids[user.id] = true
      next if !user.preferences
      next if !user.preferences['notification_config']
      matrix = user.preferences['notification_config']['matrix']
      if ticket.owner_id != user.id
        if user.preferences['notification_config']['group_ids'] ||
           (user.preferences['notification_config']['group_ids'].class == Array && (!user.preferences['notification_config']['group_ids'].empty? || user.preferences['notification_config']['group_ids'][0] != '-'))
          hit = false
          user.preferences['notification_config']['group_ids'].each {|notify_group_id|
            user.group_ids.each {|local_group_id|
              if local_group_id.to_s == notify_group_id.to_s
                hit = true
              end
            }
          }
          next if !hit
        end
      end
      next if !matrix
      next if !matrix[@p[:type]]
      data = matrix[@p[:type]]
      next if !data
      next if !data['criteria']
      channels = data['channel']
      if data['criteria']['owned_by_me'] && ticket.owner_id == user.id
        data = {
          user: user,
          channels: channels
        }
        recipients_and_channels.push data
        next
      end
      if data['criteria']['owned_by_nobody'] && ticket.owner_id == 1
        data = {
          user: user,
          channels: channels
        }
        recipients_and_channels.push data
        next
      end
      next unless data['criteria']['no']
      data = {
        user: user,
        channels: channels
      }
      recipients_and_channels.push data
      next
    }

    # send notifications
    recipient_list = ''
    recipients_and_channels.each do |item|
      user = item[:user]
      channels = item[:channels]

      # ignore user who changed it by him self via web
      if @via_web
        next if article && article.updated_by_id == user.id
        next if !article && ticket.updated_by_id == user.id
      end

      # ignore inactive users
      next if !user.active

      # ignore if no changes has been done
      changes = human_changes(user, ticket)
      next if @p[:type] == 'update' && !article && ( !changes || changes.empty? )

      # create online notification
      used_channels = []
      if channels['online']
        used_channels.push 'online'
        seen = ticket.online_notification_seen_state(user.id)
        OnlineNotification.add(
          type: @p[:type],
          object: 'Ticket',
          o_id: ticket.id,
          seen: seen,
          created_by_id: ticket.updated_by_id || 1,
          user_id: user.id,
        )
        Rails.logger.info "send ticket online notifiaction to agent (#{@p[:type]}/#{ticket.id}/#{user.email})"
      end

      # ignore email channel notificaiton and empty emails
      if !channels['email'] && (!user.email || user.email == '')
        add_recipient_list(ticket, user, used_channels)
        next
      end

      used_channels.push 'email'
      add_recipient_list(ticket, user, used_channels)

      # get user based notification template
      # if create, send create message / block update messages
      if @p[:type] == 'create'
        template = template_create(user, ticket, article, changes)
      elsif @p[:type] == 'update'
        template = template_update(user, ticket, article, changes)
      else
        fail "unknown type for notification #{@p[:type]}"
      end

      # prepare subject & body
      notification = {}
      [:subject, :body].each { |key|
        notification[key.to_sym] = NotificationFactory.build(
          locale: user.preferences[:locale],
          string: template[key],
          objects: {
            ticket: ticket,
            article: article,
            recipient: user,
          }
        )
      }

      # rebuild subject
      notification[:subject] = ticket.subject_build(notification[:subject])

      Rails.logger.info "send ticket email notifiaction to agent (#{@p[:type]}/#{ticket.id}/#{user.email})"

      NotificationFactory.send(
        recipient: user,
        subject: notification[:subject],
        body: notification[:body],
        content_type: 'text/html',
      )
    end

  end

  def add_recipient_list(ticket, user, channels)
    return if channels.empty?
    identifier = user.email
    if !identifier && identifier == ''
      identifier = user.login
    end
    recipient_list = "#{identifier}(#{channels.join(',')})"
    History.add(
      o_id: ticket.id,
      history_type: 'notification',
      history_object: 'Ticket',
      value_to: recipient_list,
      created_by_id: ticket.updated_by_id || 1
    )
  end

  def human_changes(user, record)

    return {} if !@p[:changes]

    # only show allowed attributes
    attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)
    #puts "AL #{attribute_list.inspect}"
    user_related_changes = {}
    @p[:changes].each {|key, value|

      # if no config exists, use all attributes
      if !attribute_list || attribute_list.empty?
        user_related_changes[key] = value

      # if config exists, just use existing attributes for user
      elsif attribute_list[key.to_s]
        user_related_changes[key] = value
      end
    }

    changes = {}
    user_related_changes.each {|key, value|

      # get attribute name
      attribute_name           = key.to_s
      object_manager_attribute = attribute_list[attribute_name]
      if attribute_name[-3, 3] == '_id'
        attribute_name = attribute_name[ 0, attribute_name.length - 3 ].to_s
      end

      # add item to changes hash
      if key.to_s == attribute_name
        changes[attribute_name] = value
      end

      # if changed item is an _id field/reference, do an lookup for the realy values
      value_id  = []
      value_str = [ value[0], value[1] ]
      if key.to_s[-3, 3] == '_id'
        value_id[0] = value[0]
        value_id[1] = value[1]

        if record.respond_to?( attribute_name ) && record.send(attribute_name)
          relation_class = record.send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup( id: value_id[0] )
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup( id: value_id[1] )
            if relation_model
              if relation_model['name']
                value_str[1] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[1] = relation_model.send('fullname')
              end
            end
          end
        end
      end

      # check if we have an dedcated display name for it
      display = attribute_name
      if object_manager_attribute && object_manager_attribute[:display]

        # delete old key
        changes.delete( display )

        # set new key
        display = object_manager_attribute[:display].to_s
      end
      changes[display] = if object_manager_attribute && object_manager_attribute[:translate]
                           ["i18n(#{value_str[0]})", "i18n(#{value_str[1]})"]
                         else
                           [value_str[0].to_s, value_str[1].to_s]
                         end
    }
    changes
  end

  def template_create(user, ticket, article, _ticket_changes)
    article_content = ''
    if article
      article_content = 'i18n(Information):
<blockquote type="cite">
#{article.body.text2html}
</blockquote>
<br>
<br>'
    end

    if user.preferences[:locale] =~ /^de/i
      subject = 'Neues Ticket (#{ticket.title})'
      body    = '<div>Hallo #{recipient.firstname.text2html},</div>
<br>
<div>
es wurde ein neues Ticket (#{ticket.title.text2html}) von "<b>#{ticket.updated_by.fullname.text2html}</b>" erstellt.
</div>
<br>
<div>
i18n(Group): #{ticket.group.name.text2html}<br>
i18n(Owner): #{ticket.owner.fullname.text2html}<br>
i18n(State): i18n(#{ticket.state.name.text2html})<br>
</div>
<br>
<div>
' + article_content + '
</div>
'
    else

      subject = 'New Ticket (#{ticket.title})'
      body    = '<div>Hi #{recipient.firstname.text2html},</div>
<br>
<div>
a new Ticket (#{ticket.title.text2html}) has been created by "<b>#{ticket.updated_by.fullname.text2html}</b>".
</div>
<br>
<div>
Group: #{ticket.group.name.text2html}<br>
Owner: #{ticket.owner.fullname.text2html}<br>
State: i18n(#{ticket.state.name.text2html})<br>
</div>
<br>
<div>
' + article_content + '
</div>
'

    end

    body = template_header(user) + body
    body += template_footer(user, ticket, article)

    template = {
      subject: subject,
      body: body,
    }
    template
  end

  def template_update(user, ticket, article, ticket_changes)
    changes = ''
    ticket_changes.each {|key, value|
      changes += "i18n(#{key.to_s.text2html}): #{value[0].to_s.text2html} -> #{value[1].to_s.text2html}<br>\n"
    }
    article_content = ''
    if article
      article_content = 'i18n(Information):
<blockquote type="cite">
#{article.body.text2html}
</blockquote>
<br>
<br>'
    end
    if user.preferences[:locale] =~ /^de/i
      subject = 'Ticket aktualisiert (#{ticket.title})'
      body    = '<div>Hallo #{recipient.firstname.text2html},</div>
<br>
<div>
Ticket (#{ticket.title.text2html}) wurde von "<b>#{ticket.updated_by.fullname.text2html}</b>" aktualisiert.
</div>
<br>
<div>
i18n(Changes):<br>
' + changes + '
</div>
<br>
<div>
' + article_content + '
</div>
'
    else
      subject = 'Updated Ticket (#{ticket.title})'
      body    = '<div>Hi #{recipient.firstname.text2html},</div>
<br>
<div>
Ticket (#{ticket.title.text2html}) has been updated by "<b>#{ticket.updated_by.fullname.text2html}</b>".
</div>
<br>
<div>
i18n(Changes):<br>
' + changes + '
</div>
<br>
<div>
' + article_content + '
</div>
'
    end

    body = template_header(user) + body
    body += template_footer(user, ticket, article)

    template = {
      subject: subject,
      body: body,
    }
    template
  end

  def template_header(_user)
    '
<style type="text/css">
  .header {
    color: #aaaaaa;
    border-bottom-style:solid;
    border-bottom-width:1px;
    border-bottom-color:#aaaaaa;
    width: 100%;
    max-width: 600px;
    padding-bottom: 6px;
    margin-bottom: 16px;
    padding-top: 6px;
    font-size: 16px;
  }
  .footer {
    color: #aaaaaa;
    border-top-style:solid;
    border-top-width:1px;
    border-top-color:#aaaaaa;
    width: 100%;
    max-width: 600px;
    padding-top: 6px;
    margin-top: 16px;
    padding-botton: 6px;
  }
  .footer a {
    color: #aaaaaa;
  }
</style>

<div class="header">
  #{config.product_name} i18n(Notification)
</div>
'
  end

  def template_footer(_user, _ticket, _article)
    '
<p>
  <a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}" target="zammad_app">i18n(View this in Zammad)</a>
</p>
<div class="footer">
  <a href="#{config.http_type}://#{config.fqdn}/#profile/notifications">i18n(Manage your notifications settings)</a>
</div>
'
  end
end
