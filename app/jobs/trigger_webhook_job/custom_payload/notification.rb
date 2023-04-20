# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::Notification
  Notification = Struct.new('Notification', :subject, :message, :link, :changes, :body)

  def self.generate(tracks = {}, event)
    return '\#{bad event}' if event.exclude?(:execution)

    type = type!(event)
    return '\#{bad type}' if type.blank?

    template = fetch(tracks, event, type)
    assemble(template, has_article: tracks[:article].present?)
  end

  # private class methods

  def self.fetch(tracks, event, type)
    NotificationFactory::Messaging.template(
      template: "ticket_#{type}",
      locale:   Setting.get('locale_default') || 'en-us',
      timezone: Setting.get('timezone_default_sanitized'),
      objects:  {
        ticket:       tracks.fetch(:ticket, nil),
        article:      tracks.fetch(:article, nil),
        current_user: event[:user_id].present? ? User.lookup(id: event[:user_id]) : nil,
        changes:      event[:changes],
      },
    )
  end

  def self.type!(event)
    return 'info' if event[:execution].eql?('job')
    return event[:type] if event[:execution].eql?('trigger')

    nil
  end

  def self.assemble(template, has_article: false)
    match = regex(has_article).match(template[:body])
    notification = {
      subject: template[:subject][2..],
      message: match[:message].presence || '',
      link:    match[:link].presence || '',
      changes: match[:changes].presence || '',
      body:    has_article ? match[:body].presence || '' : '',
    }

    sanitize(notification)
    Notification.new(*notification.values)
  end

  def self.regex(extended)
    source = '_<(?<link>.+)\|.+>:(?<message>.+)_\n(?<changes>.+)?'
    source = "#{source}\n{3,4}(?<body>.+)?" if extended

    Regexp.new(source, Regexp::MULTILINE)
  end

  def self.sanitize(hash)
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

  private_class_method %i[
    assemble
    fetch
    regex
    sanitize
    type!
  ]
end
