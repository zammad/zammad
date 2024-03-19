# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TriggerWebhookJob::CustomPayload::Track::Notification < TriggerWebhookJob::CustomPayload::Track
  class << self
    def root?
      true
    end

    def klass
      'Struct::Notification'
    end

    def functions
      %w[
        subject
        link
        message
        body
        changes
      ].freeze
    end

    def replacements(pre_defined_webhook_type:)
      {
        notification: functions,
      }
    end

    Notification = Struct.new('Notification', :subject, :message, :link, :changes, :body)

    def generate(tracks, data)
      return if data[:event].blank?

      event = data[:event]
      raise ArgumentError, __("The required event field 'execution' is missing.") if event.exclude?(:execution)

      type = type!(event)
      template = fetch(tracks, event, type)
      tracks[:notification] = assemble(template, has_body: tracks[:article].present? && tracks[:article].body_as_text.strip.present?)
    end

    private

    def fetch(tracks, event, type)
      NotificationFactory::Messaging.template(
        template: "ticket_#{type}",
        locale:   Setting.get('locale_default') || 'en-us',
        timezone: Setting.get('timezone_default'),
        objects:  {
          ticket:       tracks.fetch(:ticket, nil),
          article:      tracks.fetch(:article, nil),
          current_user: event[:user_id].present? ? ::User.lookup(id: event[:user_id]) : nil,
          changes:      event[:changes],
        },
      )
    end

    def type!(event)
      return 'info' if event[:execution].eql?('job')
      return event[:type] if event[:execution].eql?('trigger')

      raise ArgumentError, __("The required event field 'execution' is unknown or missing.")
    end

    def assemble(template, has_body: false)
      match = regex(has_body).match(template[:body])

      notification = {
        subject: template[:subject][2..],
        message: match[:message].presence || '',
        link:    match[:link].presence || '',
        changes: match[:changes].presence || '',
        body:    has_body ? match[:body].presence || '' : '',
      }

      sanitize(notification)
      Notification.new(*notification.values)
    end

    def regex(extended)
      source = '_<(?<link>.+)\|.+>:(?<message>.+)_(\n(?<changes>.+))?'
      source += '\n{3,4}(?<body>.+)?' if extended

      Regexp.new(source, Regexp::MULTILINE)
    end

    def sanitize(hash)
      hash.each do |key, value|
        if key.eql?(:changes)
          value = value
            .split(%r{\n})
            .map(&:strip)
            .compact_blank
            .join('\n')
        end

        hash[key] = value.strip
      end
    end
  end
end
