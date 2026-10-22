# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::Sms::Telnyx < Channel::Driver::Sms::Base
  NAME = 'sms/telnyx'.freeze

  API_URL = 'https://api.telnyx.com/v2/messages'.freeze

  INBOUND_EVENT_TYPE = 'message.received'.freeze

  SIGNATURE_HEADER = 'telnyx-signature-ed25519'.freeze
  TIMESTAMP_HEADER = 'telnyx-timestamp'.freeze

  SIGNATURE_TOLERANCE = 300

  # Telnyx publishes the raw 32 key bytes; OpenSSL reads them wrapped in a SubjectPublicKeyInfo.
  ED25519_SPKI_PREFIX = ['302a300506032b6570032100'].pack('H*').freeze

  def fetchable?(_channel)
    false
  end

  def deliver(options, attr, _notification = false) # rubocop:disable Style/OptionalBooleanParameter
    Rails.logger.info "Sending SMS to recipient #{attr[:recipient]}"

    return true if Setting.get('import_mode')

    Rails.logger.info "Backend sending Telnyx SMS to #{attr[:recipient]}"
    begin
      send_create(options, attr)
      true
    rescue => e
      Rails.logger.error { "Telnyx error: #{e.inspect}" }
      raise e
    end
  end

  def send_create(options, attr)
    return if Setting.get('developer_mode')

    response = UserAgent.post(
      API_URL,
      {
        from: options[:sender],
        to:   attr[:recipient],
        text: attr[:message],
      },
      {
        json:                    true,
        bearer_token:            options[:token],
        do_not_follow_redirects: true,
      },
    )

    raise send_error_message(response) if !response.success?
    raise "Telnyx API error (HTTP #{response.code}): response does not contain an accepted message id" if accepted_message_id(response).blank?
  end

  def process(options, attr, channel)
    verify_signature!(options, attr)

    message = inbound_message(attr[:raw_body])
    return [:json, {}] if !message

    Rails.logger.info "Receiving SMS from #{message[:from]}"

    channel.with_lock(requires_new: true) do
      next if Ticket::Article.exists?(message_id: message[:id], message_id_md5: Digest::MD5.hexdigest(message[:id]))

      user = user_by_mobile(message[:from])

      UserInfo.with_user_id(user.id) do
        process_ticket(message, channel, user)
      end
    end

    [:json, {}]
  end

  def create_ticket(attr, channel, user)
    ticket = Ticket.new(
      group_id:    channel.group_id,
      title:       cut_title(attr[:text]),
      state_id:    Ticket::State.find_by(default_create: true).id,
      priority_id: Ticket::Priority.find_by(default_create: true).id,
      customer_id: user.id,
      preferences: {
        channel_id: channel.id,
        sms:        {
          messaging_profile_id: attr[:messaging_profile_id],
          from:                 attr[:from],
          to:                   attr[:to],
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
      body:         attr[:text],
      from:         attr[:from],
      to:           attr[:to],
      message_id:   attr[:id],
      content_type: 'text/plain',
      preferences:  {
        channel_id: channel.id,
        sms:        {
          messaging_profile_id: attr[:messaging_profile_id],
          from:                 attr[:from],
          to:                   attr[:to],
          type:                 attr[:type],
          media:                attr[:media],
        },
      }
    )
  end

  def self.definition
    {
      name:         'Telnyx',
      adapter:      'sms/telnyx',
      account:      [
        { name: 'options::webhook_token', display: __('Webhook Token'), tag: 'input', type: 'text', limit: 200, null: false, default: Digest::MD5.hexdigest(SecureRandom.uuid), disabled: true, readonly: true },
        { name: 'options::token', display: __('API key'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'KEYXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' },
        { name: 'options::public_key', display: __('Public key'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=' },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+15551234567' },
        { name: 'group_id', display: __('Destination Group'), tag: 'tree_select', null: false, relation: 'Group', nulloption: true, filter: { active: true } },
      ],
      notification: [
        { name: 'options::token', display: __('API key'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: 'KEYXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' },
        { name: 'options::sender', display: __('Sender'), tag: 'input', type: 'text', limit: 200, null: false, placeholder: '+15551234567' },
      ],
    }
  end

  private

  def accepted_message_id(response)
    data = response.data.is_a?(Hash) ? response.data['data'] : nil
    return if !data.is_a?(Hash)

    data['id'].presence
  end

  def send_error_message(response)
    "Telnyx API error (HTTP #{response.code}): #{api_error_details(response.body).presence || response.error}"
  end

  def api_error_details(body)
    parsed = JSON.parse(body.to_s)
    return if !parsed.is_a?(Hash) || !parsed['errors'].is_a?(Array)

    parsed['errors']
      .grep(Hash)
      .filter_map { |error| error.values_at('code', 'title', 'detail').compact_blank.join(' - ').presence }
      .join('; ')
  rescue JSON::ParserError
    nil
  end

  def verify_signature!(options, attr)
    public_key = ed25519_public_key(options[:public_key])
    headers    = attr[:headers] || {}
    signature  = headers[SIGNATURE_HEADER]
    timestamp  = headers[TIMESTAMP_HEADER]

    raise Exceptions::Forbidden, __('Telnyx webhooks are only accepted via POST.') if attr[:request_method] != 'POST'
    raise Exceptions::Forbidden, __('Telnyx webhook signature headers are missing.') if signature.blank? || timestamp.blank?
    raise Exceptions::Forbidden, __('Telnyx webhook request body is missing.') if attr[:raw_body].blank?

    verify_timestamp!(timestamp)

    signed_payload = "#{timestamp}|#{attr[:raw_body]}"
    return if public_key.verify(nil, Base64.strict_decode64(signature), signed_payload)

    raise Exceptions::Forbidden, __('Telnyx webhook signature is invalid.')
  rescue ArgumentError, OpenSSL::PKey::PKeyError
    raise Exceptions::Forbidden, __('Telnyx webhook signature is invalid.')
  end

  def verify_timestamp!(timestamp)
    parsed = Integer(timestamp, 10)

    return if (Time.zone.now.to_i - parsed).abs <= SIGNATURE_TOLERANCE

    raise Exceptions::Forbidden, __('Telnyx webhook timestamp is outside of the accepted tolerance.')
  rescue ArgumentError, TypeError
    raise Exceptions::Forbidden, __('Telnyx webhook timestamp is invalid.')
  end

  def ed25519_public_key(encoded)
    raise Exceptions::UnprocessableContent, __('Telnyx public key is missing in the channel configuration.') if encoded.blank?

    raw = Base64.strict_decode64(encoded.strip)
    raise ArgumentError if raw.bytesize != 32

    OpenSSL::PKey.read(ED25519_SPKI_PREFIX + raw)
  rescue ArgumentError, OpenSSL::PKey::PKeyError
    raise Exceptions::UnprocessableContent, __('Telnyx public key in the channel configuration is invalid.')
  end

  # Only the signed bytes are trusted; the parsed request params may also carry unsigned query or form data.
  # Returns nil for signed events that carry no inbound message, e.g. delivery reports.
  def inbound_message(raw_body)
    payload = inbound_payload(raw_body)
    return if !payload

    text  = payload['text']
    media = payload['media']
    validate_content!(text, media)

    {
      id:                   payload['id'],
      from:                 phone_number(payload['from']),
      to:                   phone_number(Array.wrap(payload['to']).first),
      text:                 text.to_s,
      type:                 payload['type'],
      media:                Array.wrap(media),
      messaging_profile_id: payload['messaging_profile_id'],
    }
  end

  def inbound_payload(raw_body)
    data = parse_event(raw_body)['data']
    invalid_payload! if !data.is_a?(Hash) || !present_string?(data['event_type'])

    return if data['event_type'] != INBOUND_EVENT_TYPE

    payload = data['payload']
    invalid_payload! if !payload.is_a?(Hash) || !present_string?(payload['id'])

    payload
  end

  def parse_event(raw_body)
    event = JSON.parse(raw_body)
    invalid_payload! if !event.is_a?(Hash)

    event
  rescue JSON::ParserError
    invalid_payload!
  end

  def validate_content!(text, media)
    invalid_payload! if !text.nil? && !text.is_a?(String)
    invalid_payload! if !media.nil? && !media.is_a?(Array)
    invalid_payload! if text.blank? && media.blank?
  end

  def phone_number(party)
    invalid_payload! if !party.is_a?(Hash) || !present_string?(party['phone_number'])

    party['phone_number']
  end

  def present_string?(value)
    value.is_a?(String) && value.present?
  end

  def invalid_payload!
    raise Exceptions::UnprocessableContent, __('Telnyx webhook payload is invalid.')
  end
end
