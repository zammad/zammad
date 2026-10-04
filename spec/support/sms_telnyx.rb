# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Builds Telnyx webhook events and signatures following the shapes documented at
# https://developers.telnyx.com/docs/messaging/messages/receive-message
module SmsTelnyxHelper
  TELNYX_MESSAGING_PROFILE_ID = '740572b6-099c-44a1-89b9-6c92163bc68d'.freeze
  TELNYX_CUSTOMER_NUMBER      = '+491710000000'.freeze
  TELNYX_ZAMMAD_NUMBER        = '+4915700000000'.freeze

  TELNYX_INBOUND_MESSAGES = {
    inbound_sms1: {
      id:   '84cca175-9755-4859-b67f-4730d7f58001',
      text: 'Ldfhxhcuffufuf. Fifififig.  Fifififiif Fifififiif Fifififiif Fifififiif Fifififiif',
    },
    inbound_sms2: {
      id:   '84cca175-9755-4859-b67f-4730d7f58002',
      text: 'Follow-up',
    },
    inbound_sms3: {
      id:   '84cca175-9755-4859-b67f-4730d7f58003',
      text: 'new 2',
    },
    inbound_mms1: {
      id:    '84cca175-9755-4859-b67f-4730d7f58004',
      text:  '',
      type:  'MMS',
      media: [
        {
          content_type: 'image/jpeg',
          sha256:       '3f2b1c0d7b0e5a9f8c6d4e2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c',
          size:         48_213,
          url:          'https://media.telnyx.com/XXXXXX',
        },
      ],
    },
  }.freeze

  TELNYX_OUTBOUND_EVENTS = {
    message_sent:      { event_type: 'message.sent', status: 'sent' },
    message_finalized: { event_type: 'message.finalized', status: 'delivered' },
  }.freeze

  def telnyx_webhook_event(name, **payload_overrides)
    event_type, payload = if TELNYX_INBOUND_MESSAGES.key?(name)
                            ['message.received', telnyx_inbound_payload(TELNYX_INBOUND_MESSAGES[name])]
                          else
                            telnyx_outbound_event(TELNYX_OUTBOUND_EVENTS.fetch(name))
                          end

    {
      data: {
        event_type:  event_type,
        id:          payload[:id].sub('84cca175-9755-4859-b67f', 'b301ed3f-1490-491f-995f'),
        occurred_at: '2024-01-15T20:16:07.588+00:00',
        payload:     payload.merge(payload_overrides),
        record_type: 'event',
      },
      meta: {
        attempt:      1,
        delivered_to: 'https://zammad.example.com/api/v1/sms_webhook/secret_webhook_token',
      },
    }
  end

  def telnyx_webhook_body(name, **)
    JSON.pretty_generate(telnyx_webhook_event(name, **))
  end

  def telnyx_public_key(signing_key)
    Base64.strict_encode64(signing_key.public_to_der.last(32))
  end

  def telnyx_webhook_signature(body, timestamp:, key:)
    Base64.strict_encode64(key.sign(nil, "#{timestamp}|#{body}"))
  end

  private

  def telnyx_inbound_payload(message)
    {
      direction:            'inbound',
      encoding:             'GSM-7',
      from:                 { carrier: 'T-Mobile', line_type: 'long_code', phone_number: TELNYX_CUSTOMER_NUMBER, status: 'webhook_delivered' },
      id:                   message[:id],
      media:                message.fetch(:media, []),
      messaging_profile_id: TELNYX_MESSAGING_PROFILE_ID,
      parts:                1,
      received_at:          '2024-01-15T20:16:07.503+00:00',
      record_type:          'message',
      text:                 message[:text],
      to:                   [{ carrier: 'Telnyx', line_type: 'Wireless', phone_number: TELNYX_ZAMMAD_NUMBER, status: 'webhook_delivered' }],
      type:                 message.fetch(:type, 'SMS'),
    }
  end

  def telnyx_outbound_event(event)
    payload = {
      direction:            'outbound',
      encoding:             'GSM-7',
      errors:               [],
      from:                 { carrier: 'Telnyx', line_type: 'Wireless', phone_number: TELNYX_ZAMMAD_NUMBER },
      id:                   '84cca175-9755-4859-b67f-4730d7f58005',
      media:                [],
      messaging_profile_id: TELNYX_MESSAGING_PROFILE_ID,
      parts:                1,
      record_type:          'message',
      sent_at:              '2024-01-15T20:20:06.503+00:00',
      text:                 'some test',
      to:                   [{ carrier: 'T-Mobile', line_type: 'long_code', phone_number: TELNYX_CUSTOMER_NUMBER, status: event[:status] }],
      type:                 'SMS',
    }

    [event[:event_type], payload]
  end
end

RSpec.configure do |config|
  config.include SmsTelnyxHelper, sms_telnyx: true
end
