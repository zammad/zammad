module NotificationFactory

=begin

  result = NotificationFactory.template_read(
    template: 'password_reset',
    locale: 'en-us',
    format: 'html',
    type: 'mailer',
  )

or

  result = NotificationFactory.template_read(
    template: 'ticket_update',
    locale: 'en-us',
    format: 'md',
    type: 'slack',
  )

returns

  {
    subject: 'some subject',
    body: 'some body',
  }

=end

  def self.template_read(data)

    template_subject = nil
    template_body = ''
    locale = data[:locale] || 'en'
    template = data[:template]
    format = data[:format]
    type = data[:type]
    root = Rails.root
    location = "#{root}/app/views/#{type}/#{template}/#{locale}.#{format}.erb"

    # as fallback, use 2 char locale
    if !File.exist?(location)
      locale = locale[0, 2]
      location = "#{root}/app/views/#{type}/#{template}/#{locale}.#{format}.erb"
    end

    # as fallback, use en
    if !File.exist?(location)
      location = "#{root}/app/views/#{type}/#{template}/en.#{format}.erb"
    end

    File.open(location, 'r:UTF-8').each do |line|
      if !template_subject
        template_subject = line
        next
      end
      template_body += line
    end
    {
      subject: template_subject,
      body: template_body,
    }
  end

=begin

  string = NotificationFactory.application_template_read(
    format: 'html',
    type: 'mailer',
  )

or

  string = NotificationFactory.application_template_read(
    format: 'md',
    type: 'slack',
  )

returns

  'some template'

=end

  def self.application_template_read(data)
    format = data[:format]
    type = data[:type]
    root = Rails.root
    application_template = nil
    File.open("#{root}/app/views/#{type}/application.#{format}.erb", 'r:UTF-8') do |file|
      application_template = file.read
    end
    application_template
  end

end
