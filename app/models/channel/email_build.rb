# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'mail'

class Channel::EmailBuild

  def build(attr, notification = false)
    mail = Mail.new

    # set organization
    organization = Setting.get('organization')
    if organization then;
      mail['Organization'] = organization.to_s
    end

    # notification
    if notification
      attr['X-Loop']         = 'yes'
      attr['Precedence']     = 'bulk'
      attr['Auto-Submitted'] = 'auto-generated'
    end

    attr['X-Powered-BY'] = 'OTRS - Open Ticket Request System (http://otrs.org/)'
    attr['X-Mailer'] = 'OTRS Mail Service (3.x)'

    # set headers
    attr.each do |key, v|
      if key.to_s != 'attachments' && key.to_s != 'body'
        mail[key.to_s] = v.to_s
      end
    end

    # add body
    mail.text_part = Mail::Part.new do
      body attr[:body]
    end

    # add attachments
    if attr[:attachments]
      attr[:attachments].each do |attachment|
        mail.attachments[attachment.filename] = {
          :content_type => attachment.preferences['Content-Type'],
          :mime_type    => attachment.preferences['Mime-Type'],
          :content      => attachment.content
        }
      end
    end
    return mail
  end
end
