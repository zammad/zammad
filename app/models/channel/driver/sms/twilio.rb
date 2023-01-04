# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sms::Twilio < Channel::Driver::Sms::Base
  NAME = 'sms/twilio'.freeze

  def fetchable?(_channel)
    false
  end

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Twilio SMS to #{attr[:recipient]}"
    begin
      send_create(options, attr)

      true
    rescue => e
      Rails.logger.debug { "Twilio error: #{e.inspect}" }
      raise e
    end
  end

  def send_create(options, attr)
    return if Setting.get('developer_mode')

    result = api(options).messages.create(
      from: options[:sender],
      to:   attr[:recipient],
      body: attr[:message],
    )

    raise result.error_message if result&.error_code&.positive?
  end

  def process(_options, attr, channel)
    Rails.logger.info "Receiving SMS frim recipient #{attr[:From]}"

    # prevent already created articles
    if Ticket::Article.exists?(message_id: attr[:SmsMessageSid])
      require 'twilio-ruby' # Only load this gem when it is really used
      return ['application/xml; charset=UTF-8;', Twilio::TwiML::MessagingResponse.new.to_s]
    end

    user = user_by_mobile(attr[:From])
    UserInfo.current_user_id = user.id

    process_ticket(attr, channel, user)

    require 'twilio-ruby'  # Only load this gem when it is really used
    ['application/xml; charset=UTF-8;', Twilio::TwiML::MessagingResponse.new.to_s]
  end

  def create_ticket(attr, channel, user)
    title = cut_title(attr[:Body])
    ticket = Ticket.new(
      group_id:    channel.group_id,
      title:       title,
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: channel.id,
        sms:        {
          AccountSid: attr['AccountSid'],
          From:       attr['From'],
          To:         attr['To'],
        }
      }
    )
    ticket.save!
    ticket
  end

  def create_article(attr, channel, ticket)
    Ticket::Article.create!(
      ticket_id:    ticket.id,
      type:         article_type_sms,
      sender:       Ticket::Article::Sender.find_by(name: 'Customer'),
      body:         attr[:Body],
      from:         attr[:From],
      to:           attr[:To],
      message_id:   attr[:SmsMessageSid],
      content_type: 'text/plain',
      preferences:  {
        channel_id: channel.id,
        sms:        {
          AccountSid: attr['AccountSid'],
          From:       attr['From'],
          To:         attr['To'],
        }
      }
    )
  end

  def self.definition
    {
      name:         'twilio',
      adapter:      'sms/twilio',
      account:      [
        { name: 'options::webhook_token', display: __('Webhook Token'), tag: 'input', type: 'text', limit: 200, null: false, default: Digest::MD5.hexdigest(SecureRandom.uuid), disabled: true, readonly: true },
        { name: 'options::account_id', display: __('Account SID'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXX' },
        { name: 'options::token', display: __('Token'), tag: 'input', type: 'text', limit: 200, null: false },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
        { name: 'group_id', display: __('Destination Group'), tag: 'select', null: false, relation: 'Group', nulloption: true, filter: { active: true } },
      ],
      notification: [
        { name: 'options::account_id', display: __('Account SID'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXX' },
        { name: 'options::token', display: __('Token'), tag: 'input', type: 'text', limit: 200, null: false },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
      ],
    }
  end

  private

  def api(options)
    require 'twilio-ruby'  # Only load this gem when it is really used.
    @api ||= ::Twilio::REST::Client.new options[:account_id], options[:token]
  end
end
