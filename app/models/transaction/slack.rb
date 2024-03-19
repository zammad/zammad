# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Transaction::Slack
  include ChecksHumanChanges

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
    changes = human_changes(@item[:changes], ticket)
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

    result = NotificationFactory::Messaging.template(
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

    config['items'].each do |local_config|
      next if local_config['webhook'].blank?

      # check if reminder_reached/escalation/escalation_warning is already sent today
      md5_webhook = Digest::MD5.hexdigest(local_config['webhook'])
      cache_key = "slack::backend::#{@item[:type]}::#{ticket.id}::#{md5_webhook}"
      if sent_value
        value = Rails.cache.read(cache_key)
        if value == sent_value
          Rails.logger.debug { "did not send webhook, already sent (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
          next
        end
        Rails.cache.write(
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

      icon_url = 'https://zammad.com/assets/images/logo-200x200.png'
      if local_config['icon_url'].present?
        icon_url = local_config['icon_url']
      end

      Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }

      require 'slack-notifier' # Only load this gem when it is really used.
      notifier = Slack::Notifier.new(
        local_config['webhook'],
        channel:     local_config['channel'],
        username:    local_config['username'],
        icon_url:    icon_url,
        mrkdwn:      true,
        http_client: Transaction::Slack::Client,
      )
      if local_config['expand']
        body = "#{result[:subject]}\n#{result[:body]}"
        result_ping = notifier.ping body
      else
        attachment = {
          text:      result[:body],
          mrkdwn_in: ['text'],
          color:     ticket.current_state_color,
        }
        result_ping = notifier.ping result[:subject],
                                    attachments: [attachment]
      end
      if !result_ping.empty? && !result_ping[0].success?
        if sent_value
          Rails.cache.delete(cache_key)
        end
        Rails.logger.error "Unable to post webhook: #{local_config['webhook']}: #{result_ping.inspect}"
        next
      end
      Rails.logger.debug { "sent webhook (#{@item[:type]}/#{ticket.id}/#{local_config['webhook']})" }
    end

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
          },
          verify_ssl:    true,
        },
      )
    end
  end

end
