# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction::Slack

=begin

  backend = Transaction::Slack.new(
    object: 'Ticket',
    type: 'update',
    object_id: 123,
    interface_handle: 'application_server', # application_server|websocket|scheduler
    changes: {
      'attribute1' => [before, now],
      'attribute2' => [before, now],
    },
    created_at: Time.zone.now,
    user_id: 123,
  )
  backend.perform

=end

  def initialize(item, params = {})
    @item = item
    @params = params
  end

  def perform

    # return if we run import mode
    return if Setting.get('import_mode')

    return if @item[:object] != 'Ticket'
    return if !Setting.get('slack_integration')

    config = Setting.get('slack_config')
    return if !config
    return if !config['items']

    ticket = Ticket.find_by(id: @item[:object_id])
    return if !ticket

    if @item[:article_id]
      article = Ticket::Article.find(@item[:article_id])

      # ignore notifications
      sender = Ticket::Article::Sender.lookup(id: article.sender_id)
      if sender&.name == 'System'
        return if @item[:changes].blank?

        article = nil
      end
    end

    # ignore if no changes has been done
    changes = human_changes(ticket)
    return if @item[:type] == 'update' && !article && changes.blank?

    # get user based notification template
    # if create, send create message / block update messages
    template = nil
    sent_value = nil
    case @item[:type]
    when 'create'
      template = 'ticket_create'
    when 'update'
      template = 'ticket_update'
    when 'reminder_reached'
      template = 'ticket_reminder_reached'
      sent_value = ticket.pending_time
    when 'escalation'
      template = 'ticket_escalation'
      sent_value = ticket.escalation_at
    when 'escalation_warning'
      template = 'ticket_escalation_warning'
      sent_value = ticket.escalation_at
    else
      raise "unknown type for notification #{@item[:type]}"
    end

    user = User.find(1)

    current_user = User.lookup(id: @item[:user_id])
    if !current_user
      current_user = User.lookup(id: 1)
    end

    result = NotificationFactory::Slack.template(
      template: template,
      locale:   user.locale,
      timezone: Setting.get('timezone_default'),
      objects:  {
        ticket:       ticket,
        article:      article,
        current_user: current_user,
        changes:      changes,
      },
    )

    # good, warning, danger
    color = '#000000'
    ticket_state_type = ticket.state.state_type.name
    if ticket.escalation_at && ticket.escalation_at < Time.zone.now
      color = '#f35912'
    elsif ticket_state_type == 'pending reminder'
      if ticket.pending_time && ticket.pending_time < Time.zone.now
        color = '#faab00'
      end
    elsif ticket_state_type.match?(%r{^(new|open)$})
      color = '#faab00'
    elsif ticket_state_type == 'closed'
      color = '#38ad69'
    end

    config['items'].each do |local_config|
      next if local_config['webhook'].blank?

      # check if reminder_reached/escalation/escalation_warning is already sent today
      md5_webhook = Digest::MD5.hexdigest(local_config['webhook'])
      cache_key = "slack::backend::#{@item[:type]}::#{ticket.id}::#{md5_webhook}"
      if sent_value
        value = Cache.read(cache_key)
        if value == sent_value
          Rails.logger.debug { "did not send webhook, already sent (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
          next
        end
        Cache.write(
          cache_key,
          sent_value,
          {
            expires_in: 24.hours
          },
        )
      end

      # check action
      if local_config['types'].instance_of?(Array)
        hit = false
        local_config['types'].each do |type|
          next if type.to_s != @item[:type].to_s

          hit = true
          break
        end
        next if !hit
      elsif local_config['types']
        next if local_config['types'].to_s != @item[:type].to_s
      end

      # check group
      if local_config['group_ids'].instance_of?(Array)
        hit = false
        local_config['group_ids'].each do |group_id|
          next if group_id.to_s != ticket.group_id.to_s

          hit = true
          break
        end
        next if !hit
      elsif local_config['group_ids']
        next if local_config['group_ids'].to_s != ticket.group_id.to_s
      end

      logo_url = 'https://zammad.com/assets/images/logo-200x200.png'
      if local_config['logo_url'].present?
        logo_url = local_config['logo_url']
      end

      Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }

      notifier = Slack::Notifier.new(
        local_config['webhook'],
        channel:     local_config['channel'],
        username:    local_config['username'],
        icon_url:    logo_url,
        mrkdwn:      true,
        http_client: Transaction::Slack::Client,
      )
      if local_config['expand']
        body = "#{result[:subject]}\n#{result[:body]}"
        result = notifier.ping body
      else
        attachment = {
          text:      result[:body],
          mrkdwn_in: ['text'],
          color:     color,
        }
        result = notifier.ping result[:subject],
                               attachments: [attachment]
      end
      if !result.empty? && !result[0].success?
        if sent_value
          Cache.delete(cache_key)
        end
        Rails.logger.error "Unable to post webhook: #{local_config['webhook']}: #{result.inspect}"
        next
      end
      Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
    end

  end

  def human_changes(record)

    return {} if !@item[:changes]

    user = User.find(1)
    locale = user.preferences[:locale] || Setting.get('locale_default') || 'en-us'

    # only show allowed attributes
    attribute_list = ObjectManager::Object.new('Ticket').attributes(user).index_by { |item| item[:name] }
    #puts "AL #{attribute_list.inspect}"
    user_related_changes = {}
    @item[:changes].each do |key, value|

      # if no config exists, use all attributes
      # or if config exists, just use existing attributes for user
      if attribute_list.blank? || attribute_list[key.to_s]
        user_related_changes[key] = value
      end
    end

    changes = {}
    user_related_changes.each do |key, value|

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

      # if changed item is an _id field/reference, look up the real values
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

      # check if we have a dedicated display name for it
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
    end
    changes
  end

  class Transaction::Slack::Client
    def self.post(uri, params = {})
      UserAgent.post(
        uri.to_s,
        params,
        {
          open_timeout:  4,
          read_timeout:  10,
          total_timeout: 20,
          log:           {
            facility: 'slack_webhook',
          }
        },
      )
    end
  end

end
