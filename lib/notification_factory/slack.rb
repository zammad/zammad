# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class NotificationFactory::Slack

=begin

  result = NotificationFactory::Slack.template(
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

    if data[:templateInline]
      return NotificationFactory::Renderer.new(
        objects:  data[:objects],
        locale:   data[:locale],
        timezone: data[:timezone],
        template: data[:templateInline]
      ).render
    end

    template = NotificationFactory.template_read(
      locale:   data[:locale] || Locale.default,
      template: data[:template],
      format:   'md',
      type:     'slack',
    )

    message_subject = NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: template[:subject],
      escape:   false
    ).render
    message_body = NotificationFactory::Renderer.new(
      objects:  data[:objects],
      locale:   data[:locale],
      timezone: data[:timezone],
      template: template[:body],
      escape:   false
    ).render

    if !data[:raw]
      application_template = NotificationFactory.application_template_read(
        format: 'md',
        type:   'slack',
      )
      data[:objects][:message] = message_body
      data[:objects][:standalone] = data[:standalone]
      message_body = NotificationFactory::Renderer.new(
        objects:  data[:objects],
        locale:   data[:locale],
        timezone: data[:timezone],
        template: application_template,
        escape:   false
      ).render
    end
    {
      subject: message_subject.strip!,
      body:    message_body.strip!,
    }
  end

end
