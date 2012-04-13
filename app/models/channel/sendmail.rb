class Channel::Sendmail < Channel::EmailBuild
  include UserInfo
  def send(attr, channel, notification = false)
    mail = build(attr, notification)
    mail.delivery_method :sendmail
    mail.deliver    
  end
end