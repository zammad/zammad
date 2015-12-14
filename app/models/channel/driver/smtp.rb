# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Smtp

=begin

  instance = Channel::Driver::Smtp.new
  instance.send(
    {
      host:                 'some.host',
      port:                 25,
      enable_starttls_auto: true, # optional
      user:                 'someuser',
      password:             'somepass'
    },
    mail_attributes,
    notification
  )

=end

  def send(options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    # set smtp defaults
    if !options.key?(:port)
      options[:port] = 25
    end
    if !options.key?(:enable_starttls_auto)
      options[:enable_starttls_auto] = true
    end
    if !options.key?(:openssl_verify_mode)
      options[:openssl_verify_mode] = 'none'
    end
    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method :smtp, {
      openssl_verify_mode: options[:openssl_verify_mode],
      address: options[:host],
      port: options[:port],
      domain: options[:host],
      user_name: options[:user],
      password: options[:password],
      enable_starttls_auto: options[:enable_starttls_auto],
    }
    mail.deliver
  end
end
