# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Sms::Twilio
  NAME = 'sms/twilio'.freeze

  def fetchable?(_channel)
    false
  end

  def send(options, attr, _notification = false)
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Twilio SMS to #{attr[:recipient]}"
    begin
      if Setting.get('developer_mode') != true
        result = api(options).messages.create(
          from: options[:sender],
          to:   attr[:recipient],
          body: attr[:message],
        )

        raise result.error_message if result.error_code.positive?
      end

      true
    rescue => e
      Rails.logger.debug "Twilio error: #{e.inspect}"
      raise e
    end
  end

  def process(_options, attr, channel)
    Rails.logger.info "Receiving SMS frim recipient #{attr[:From]}"

    # prevent already created articles
    if Ticket::Article.exists?(message_id: attr[:SmsMessageSid])
      return ['application/xml; charset=UTF-8;', Twilio::TwiML::MessagingResponse.new.to_s]
    end

    # find sender
    user = User.where(mobile: attr[:From]).order(:updated_at).first
    if !user
      _from_comment, preferences = Cti::CallerId.get_comment_preferences(attr[:From], 'from')
      if preferences && preferences['from'] && preferences['from'][0] && preferences['from'][0]['level'] == 'known' && preferences['from'][0]['object'] == 'User'
        user = User.find_by(id: preferences['from'][0]['o_id'])
      end
    end
    if !user
      user = User.create!(
        firstname: attr[:From],
        mobile:    attr[:From],
      )
    end

    UserInfo.current_user_id = user.id

    # find ticket
    article_type_sms = Ticket::Article::Type.find_by(name: 'sms')
    state_ids = Ticket::State.where(name: %w[closed merged removed]).pluck(:id)
    ticket = Ticket.where(customer_id: user.id, create_article_type_id: article_type_sms.id).where.not(state_id: state_ids).order(:updated_at).first
    if ticket
      new_state = Ticket::State.find_by(default_create: true)
      if ticket.state_id != new_state.id
        ticket.state = Ticket::State.find_by(default_follow_up: true)
        ticket.save!
      end
    else
      if channel.group_id.blank?
        raise Exceptions::UnprocessableEntity, 'Group needed in channel definition!'
      end

      group = Group.find_by(id: channel.group_id)
      if !group
        raise Exceptions::UnprocessableEntity, 'Group is invalid!'
      end

      title = attr[:Body]
      if title.length > 40
        title = "#{title[0, 40]}..."
      end
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
    end

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

    ['application/xml; charset=UTF-8;', Twilio::TwiML::MessagingResponse.new.to_s]
  end

  def self.definition
    {
      name:         'twilio',
      adapter:      'sms/twilio',
      account:      [
        { name: 'options::webhook_token', display: 'Webhook Token', tag: 'input', type: 'text', limit: 200, null: false, default: Digest::MD5.hexdigest(rand(999_999_999_999).to_s), disabled: true, readonly: true },
        { name: 'options::account_id', display: 'Account SID', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXX' },
        { name: 'options::token', display: 'Token', tag: 'input', type: 'text', limit: 200, null: false },
        { name: 'options::sender', display: 'Sender', tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
        { name: 'group_id', display: 'Destination Group', tag: 'select', null: false, relation: 'Group', nulloption: true, filter: { active: true } },
      ],
      notification: [
        { name: 'options::account_id', display: 'Account SID', tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXX' },
        { name: 'options::token', display: 'Token', tag: 'input', type: 'text', limit: 200, null: false },
        { name: 'options::sender', display: 'Sender', tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+491710000000' },
      ],
    }
  end

  private

  def api(options)
    @api ||= ::Twilio::REST::Client.new options[:account_id], options[:token]
  end
end
