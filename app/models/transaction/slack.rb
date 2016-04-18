# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Slack
=begin

backend = Transaction::Slack.new(
    object: 'Ticket',
    type: 'create',
    ticket_id: 1,
)
backend.perform

  {
    object: 'Ticket',
    type: 'update',
    ticket_id: 123,
    via_web: true,
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    }
  },
=end
  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform
    return if @item[:object] != 'Ticket'
    return if !Setting.get('slack_integration')

    config = Setting.get('slack_config')
    return if !config
    return if !config['items']

    ticket = Ticket.find(@item[:ticket_id])
    if @item[:article_id]
      article = Ticket::Article.find(@item[:article_id])
    end

    # ignore if no changes has been done
    changes = human_changes(ticket)
    return if @item[:type] == 'update' && !article && (!changes || changes.empty?)

    # get user based notification template
    # if create, send create message / block update messages
    template = nil
    if @item[:type] == 'create'
      template = 'ticket_create'
    elsif @item[:type] == 'update'
      template = 'ticket_update'
    elsif @item[:type] == 'reminder_reached'
      template = 'ticket_reminder_reached'
    elsif @item[:type] == 'escalation'
      template = 'ticket_escalation'
    elsif @item[:type] == 'escalation_warning'
      template = 'ticket_escalation_warning'
    else
      raise "unknown type for notification #{@item[:type]}"
    end

    user = User.find(1)
    result = NotificationFactory::Slack.template(
      template: template,
      locale: user[:preferences][:locale],
      objects: {
        ticket: ticket,
        article: article,
        changes: changes,
      },
    )

    # good, warning, danger
    color = '#000000'
    ticket_state_type = ticket.state.state_type.name
    if ticket.escalation_time && ticket.escalation_time > Time.zone.now
      color = '#f35912'
    elsif ticket_state_type == 'pending reminder'
      if ticket.pending_time && ticket.pending_time < Time.zone.now
        color = '#faab00'
      end
    elsif ticket_state_type =~ /^(new|open)$/
      color = '#faab00'
    elsif ticket_state_type == 'closed'
      color = '#38ad69'
    end

    config['items'].each {|item|

      # check action
      if item['types'].class == Array
        hit = false
        item['types'].each {|type|
          next if type.to_s != @item[:type].to_s
          hit = true
          break
        }
        next if !hit
      elsif item['types']
        next if item['types'].to_s != @item[:type].to_s
      end

      # check group
      if item['group_ids'].class == Array
        hit = false
        item['group_ids'].each {|group_id|
          next if group_id.to_s != ticket.group_id.to_s
          hit = true
          break
        }
        next if !hit
      elsif item['group_ids']
        next if item['group_ids'].to_s != ticket.group_id.to_s
      end

      logo_url = 'https://zammad.com/assets/images/logo-200x200.png'
      if !item['logo_url'].empty?
        logo_url = item['logo_url']
      end

      Rails.logger.debug "sent webhook (#{@item[:type]}/#{ticket.id}/#{item['webhook']})"

      notifier = Slack::Notifier.new(
        item['webhook'],
        channel: item['channel'],
        username: item['username'],
        icon_url: logo_url,
        mrkdwn: true,
        http_client: Transaction::Slack::Client,
      )
      if item['expand']
        body = "#{result[:subject]}\n#{result[:body]}"
        result = notifier.ping body
      else
        attachment = {
          text: result[:body],
          mrkdwn_in: ['text'],
          color: color,
        }
        result = notifier.ping result[:subject],
                               attachments: [attachment]
      end
      if !result.success?
        Rails.logger.error "Unable to post webhook: #{item['webhook']}: #{result.inspect}"
        next
      end
      Rails.logger.debug "sent webhook (#{@item[:type]}/#{ticket.id}/#{item['webhook']})"
    }

  end

  def human_changes(record)

    return {} if !@item[:changes]
    user = User.find(1)
    locale = user.preferences[:locale] || 'en-us'

    # only show allowed attributes
    attribute_list = ObjectManager::Attribute.by_object_as_hash('Ticket', user)
    #puts "AL #{attribute_list.inspect}"
    user_related_changes = {}
    @item[:changes].each {|key, value|

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

        if record.respond_to?(attribute_name) && record.send(attribute_name)
          relation_class = record.send(attribute_name).class
          if relation_class && value_id[0]
            relation_model = relation_class.lookup(id: value_id[0])
            if relation_model
              if relation_model['name']
                value_str[0] = relation_model['name']
              elsif relation_model.respond_to?('fullname')
                value_str[0] = relation_model.send('fullname')
              end
            end
          end
          if relation_class && value_id[1]
            relation_model = relation_class.lookup(id: value_id[1])
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
        changes.delete(display)

        # set new key
        display = object_manager_attribute[:display].to_s
      end
      changes[display] = if object_manager_attribute && object_manager_attribute[:translate]
                           from = Translation.translate(locale, value_str[0])
                           to = Translation.translate(locale, value_str[1])
                           [from, to]
                         else
                           [value_str[0].to_s, value_str[1].to_s]
                         end
    }
    changes
  end

  class Transaction::Slack::Client
    def self.post(uri, params = {})
      UserAgent.post(
        uri.to_s,
        params,
        {
          open_timeout: 4,
          read_timeout: 10,
          total_timeout: 20,
          log: {
            facility: 'slack_webhook',
          }
        },
      )
    end
  end

end
