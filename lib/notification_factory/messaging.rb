# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class NotificationFactory::Messaging

=begin

  result = NotificationFactory::Messaging.template(
    template: 'ticket_update',
    locale: 'en-us',
    timezone: 'Europe/Berlin',
    objects:  {
      recipient: User.find(2),
      ticket: Ticket.find(1)
    },
  )

returns

  {
    subject: 'some subject',
    body: 'some body',
  }

=end

  def self.template(data)
    return render_inline(data) if data[:templateInline]

    messaging_template = messaging_template(data)

    message_body = render_template(messaging_template[:body], data)
    if !data[:raw]
      data = adjust_data(data, message_body)
      message_body = render_template(application_template, data)
    end

    {
      subject: render_template(messaging_template[:subject], data).strip!,
      body:    message_body.strip!,
    }
  end

  def self.messaging_template(data)
    NotificationFactory.template_read(
      locale:   data[:locale] || Locale.default,
      template: data[:template],
      format:   'md',
      type:     'messaging',
    )
  end

  def self.application_template
    NotificationFactory.application_template_read(
      format: 'md',
      type:   'messaging',
    )
  end

  def self.render_inline(data)
    NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: data[:templateInline]
    ).render
  end

  def self.render_template(template, data)
    NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: template,
      escape:   false,
      trusted:  true
    ).render
  end

  def self.adjust_data(data, message_body)
    data[:objects][:message]    = message_body
    data[:objects][:standalone] = data[:standalone]

    data
  end
end
