require 'mail'

class Channel::EmailBuild

  def build(attr, notification = false)
    mail = Mail.new

    # set organization
    organization = Setting.get('organization')
    if organization then;
      mail['organization'] = organization.to_s
    end
    
    # notification
    if notification
      attr['X-Loop']         = 'yes'
      attr['Precedence']     = 'bulk'
      attr['Auto-Submitted'] = 'auto-generated'
    end
    
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
          :content      => attachment.store_file.data
        }
      end
    end
    return mail
  end
end