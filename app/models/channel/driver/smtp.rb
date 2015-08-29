# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Smtp
  def send(options, attr, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method :smtp, {
      openssl_verify_mode: 'none',
      address: options[:host],
      port: options[:port] || 25,
      domain: options[:host],
      user_name: options[:user],
      password: options[:password],
      enable_starttls_auto: true,
    }
    mail.deliver
  end
end
