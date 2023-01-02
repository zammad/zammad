# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sms::MessageBird < Channel::Driver::Sms::Base
  NAME = 'sms/message_bird'.freeze

  def fetchable?(_channel)
    false
  end

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending MessageBird SMS to #{attr[:recipient]}"
    begin
      send_create(options, attr)
      true
    rescue => e
      Rails.logger.error { "MessageBird error: #{e.inspect}" }
      raise e
    end
  end

  def send_create(options, attr)
    return if Setting.get('developer_mode')

    api(options).message_create(options[:sender], attr[:recipient], attr[:message])
  end

  def process(_options, attr, channel)
    Rails.logger.info "Receiving SMS frim recipient #{attr['originator']}"

    # prevent already created articles
    if attr['message_id'].present? && Ticket::Article.exists?(message_id: attr['message_id'])
      return [:json, {}]
    end

    # find sender
    user = user_by_mobile(attr['originator'])
    UserInfo.current_user_id = user.id

    process_ticket(attr, channel, user)

    [:json, {}]
  end

  def create_ticket(attr, channel, user)
    title = cut_title(attr['incomingMessage'])
    ticket = Ticket.new(
      group_id:    channel.group_id,
      title:       title,
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: channel.id,
        sms:        {
          originator: attr['originator'],
          recipient:  attr['recipient'],
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
      body:         attr['incomingMessage'],
      from:         attr['originator'],
      to:           attr['recipient'],
      message_id:   attr['message_id'],
      content_type: 'text/plain',
      preferences:  {
        channel_id: channel.id,
        sms:        {
          reference: attr['reference'],
        }
      }
    )
  end

  def self.definition
    {
      name:         'message_bird',
      adapter:      'sms/message_bird',
      account:      [
        { name: 'options::webhook_token', display: __('Webhook Token'), tag: 'input', type: 'text', limit: 200, null: false, default: Digest::MD5.hexdigest(SecureRandom.uuid), disabled: true, readonly: true },
        { name: 'options::token', display: __('Token'), tag: 'input', type: 'text', limit: 255, null: false },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
        { name: 'group_id', display: __('Destination Group'), tag: 'select', null: false, relation: 'Group', nulloption: true, filter: { active: true } },
      ],
      notification: [
        { name: 'options::token', display: __('Token'), tag: 'input', type: 'text', limit: 255, null: false },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
      ],
    }
  end

  private

  def api(options)
    require 'messagebird'
    @api ||= ::MessageBird::Client.new(options[:token])
  end
end
