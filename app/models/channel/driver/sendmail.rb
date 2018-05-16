# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Channel::Driver::Sendmail
  def send(_options, attr, channel = nil, notification = false)

    # return if we run import mode
    return if Setting.get('import_mode')

    mail = Channel::EmailBuild.build(attr, notification)
    mail.delivery_method delivery_method

    if !notification && !channel.nil? && !channel.options.nil? && channel.options[:inbound].present?
      instance = Channel::Driver::Imap.new
      instance.place_reply(channel.options[:inbound][:options], mail)
    end

    mail.deliver
  end

  private

  def delivery_method
    return :test if Rails.env.test?
    :sendmail
  end
end
