# encoding: utf-8

class Observer::Ticket::Notification::BackgroundJob
  def initialize(params)
    @ticket_id  = params[:ticket_id]
    @article_id = params[:article_id]
    @type       = params[:type]
    @changes    = params[:changes]
  end
  def perform
    ticket  = Ticket.find(@ticket_id)
    if @article_id
      article = Ticket::Article.find(@article_id)
    end

    # find recipients
    recipients = []

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

    if ticket.owner_id != 1
      recipients.push ticket.owner
    else
      recipients = ticket.agent_of_group()
    end

    # send notifications
    recipient_list = ''
    recipients.each do |user|

      next if ticket.updated_by_id == user.id
      next if !user.active

      # create desktop notification

      # create online notification
      OnlineNotification.add(
        :type             => @type,
        :object           => 'Ticket',
        :o_id             => ticket.id,
        :seen             => false,
        :created_by_id    => ticket.created_by_id || 1,
        :user_id          => user.id,
      )

      # create email notification
      next if !user.email || user.email == ''

      # add recipient_list
      if recipient_list != ''
        recipient_list += ','
      end
      recipient_list += user.email.to_s

      changes = self.human_changes(user, ticket)
      next if !changes || changes.empty?

      # get user based notification template
      # if create, send create message / block update messages
      if @type == 'create'
        template = self.template_create(user, ticket, article, changes)
      elsif @type == 'update'
        template = self.template_update(user, ticket, article, changes)
      else
        raise "unknown type for notification #{@type}"
      end

      # prepare subject & body
      notification = {}
      [:subject, :body].each { |key|
        notification[key.to_sym] = NotificationFactory.build(
          :locale  => user.preferences[:locale],
          :string  => template[key],
          :objects => {
            :ticket    => ticket,
            :article   => article,
            :recipient => user,
          }
        )
      }

      # rebuild subject
      notification[:subject] = ticket.subject_build( notification[:subject] )

      # send notification
      puts "send ticket notifiaction to agent (#{@type}/#{ticket.id}/#{user.email})"

      NotificationFactory.send(
        :recipient => user,
        :subject   => notification[:subject],
        :body      => notification[:body]
      )
    end

    # add history record
    if recipient_list != ''
      History.add(
        :o_id           => ticket.id,
        :history_type   => 'notification',
        :history_object => 'Ticket',
        :value_to       => recipient_list,
        :created_by_id  => ticket.updated_by_id || 1
      )
    end
  end

  def human_changes(user, record)

    return {} if !@changes

    # only show allowed attributes
    attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)
    #puts "AL #{attribute_list.inspect}"
    user_related_changes = {}
    @changes.each {|key, value|

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
      if attribute_name[-3,3] == '_id'
        attribute_name = attribute_name[ 0, attribute_name.length-3 ]
      end
      if key == attribute_name
        changes[key] = value
      end

      value_id = []
      value_str = [ value[0], value[1] ]
      if key.to_s[-3,3] == '_id'
        value_id[0] = value[0]
        value_id[1] = value[1]

        if record.respond_to?( attribute_name ) && record.send(attribute_name)
          relation_class = record.send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup( :id => value_id[0] )
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup( :id => value_id[1] )
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
      display = attribute_name
      if object_manager_attribute && object_manager_attribute[:display]
        display = object_manager_attribute[:display]
      end
      if object_manager_attribute && object_manager_attribute[:translate]
        changes[display] = ["i18n(#{value_str[0].to_s})", "i18n(#{value_str[1].to_s})"]
      else
        changes[display] = [value_str[0].to_s, value_str[1].to_s]
      end
    }
    changes
  end

  def template_create(user, ticket, article, ticket_changes)
    article_content = ''
    if article
      article_content = '<snip>
#{article.body}
</snip>'
    end

    if user.preferences[:locale] =~ /^de/i
      subject = 'Neues Ticket (#{ticket.title})'
      body    = 'Hallo #{recipient.firstname},

es wurde ein neues Ticket (#{ticket.title}) von "#{ticket.updated_by.fullname}" erstellt.

Gruppe: #{ticket.group.name}
Besitzer: #{ticket.owner.fullname}
Status: i18n(#{ticket.state.name})

' + article_content + '

'
    else

      subject = 'New Ticket (#{ticket.title})'
      body    = 'Hi #{recipient.firstname},

a new Ticket (#{ticket.title}) has been created by "#{ticket.updated_by.fullname}".

Group: #{ticket.group.name}
Owner: #{ticket.owner.fullname}
State: i18n(#{ticket.state.name})

' + article_content + '

'

    end

    body = template_header(user) + body.chomp.text2html
    body += template_footer(user, ticket, article)

    template = {
      :subject => subject,
      :body    => body,
    }
    template
  end

  def template_update(user, ticket, article, ticket_changes)
    changes = ''
    ticket_changes.each {|key,value|
      changes += "i18n(#{key}): #{value[0]} -> #{value[1]}\n"
    }
    article_content = ''
    if article
      article_content = '<snip>
#{article.body}
</snip>'
    end
    if user.preferences[:locale] =~ /^de/i
      subject = 'Ticket aktualisiert (#{ticket.title})'
      body    = 'Hallo #{recipient.firstname},

Ticket (#{ticket.title}) wurde von "#{ticket.updated_by.fullname}" aktualisiert.

Änderungen:
' + changes + '

' + article_content + '

'
    else
      subject = 'Updated Ticket (#{ticket.title})'
      body    = 'Hi #{recipient.firstname},

Ticket (#{ticket.title}) has been updated by "#{ticket.updated_by.fullname}".

Changes:
' + changes + '

' + article_content + '

'
    end

    body = template_header(user) + body.chomp.text2html
    body += template_footer(user,ticket, article)

    template = {
      :subject => subject,
      :body    => body,
    }
    template
  end

  def template_header(user)
    '
<style type="text/css">
  p, table, div, td {
    max-width: 600px;
  }

  body{
    width:90% !important;
    -webkit-text-size-adjust:90%;
    -ms-text-size-adjust:90%;
    font-family: \'Helvetica Neue\', Helvetica, Arial, sans-serif;
    font-size: 12px;
  }
  img {
    outline:none; text-decoration:none; -ms-interpolation-mode: bicubic;
  }
  a img {
    border:none;
  }
  table td {
    border-collapse: collapse;
  }
  table {
    border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;
  }
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

  def template_footer(user, ticket, article)
    '
<a href="#{config.http_type}://#{config.fqdn}/#ticket/zoom/#{ticket.id}">i18n(View the Ticket directly here)</a>

<div class="footer">
  <a href="#{config.http_type}://#{config.fqdn}/#profile/notifications">i18n(Manage your notifications settings)</a>
</div>
'
  end
end