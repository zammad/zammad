# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module TriggerWebhookJob::CustomPayload::Notification

  def self.generate(tracks = {}, event)
    return '\#{bad event}' if event.exclude?(:execution)

    type = type!(event)
    return '\#{bad type}' if type.blank?

    notification = fetch(tracks, event, type)
    sanitize(notification[:body].to_s)
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

  # NOTE: Somewhere down in the code some weird white space replacement is
  # done. This leads to improper (Ruby) JSON formatting. This hackish method
  # works around this issue.
  def self.sanitize(string)
    string
      .gsub(%r{\n}, '\n')
      .gsub(%r{\r}, '\r')
      .gsub(%r{\t}, '\t')
      .gsub(%r{\f}, '\f')
      .gsub(%r{\v}, '\v')
  end

  private_class_method %i[
    fetch
    type!
    sanitize
  ]
end
