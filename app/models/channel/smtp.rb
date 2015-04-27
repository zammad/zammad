# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Channel::SMTP
  def send(attr, channel, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method :smtp, {
      openssl_verify_mode: 'none',
      address: channel[:options][:host],
      port: channel[:options][:port] || 25,
      domain: channel[:options][:host],
      user_name: channel[:options][:user],
      password: channel[:options][:password],
      enable_starttls_auto: true,
    }
    mail.deliver
  end
end
