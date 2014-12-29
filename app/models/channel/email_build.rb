# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'mail'

module Channel::EmailBuild

=begin

  mail = Channel::EmailBuild.build(
    :from         => 'sender@example.com',
    :to           => 'recipient@example.com',
    :body         => 'somebody with some text',
    :content_type => 'text/plain',
  )

=end

  def self.build(attr, notification = false)
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

    #attr['X-Powered-BY'] = 'Zammad - Support/Helpdesk (http://www.zammad.org/)'
    attr['X-Mailer'] = 'Zammad Mail Service (1.x)'

    # set headers
    attr.each do |key, value|
      next if key.to_s == 'attachments'
      next if key.to_s == 'body'
      next if key.to_s == 'content_type'
      mail[key.to_s] = value.to_s
    end

    # add html part
    if attr[:content_type] && attr[:content_type] == 'text/html'
      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'

        # complete check
        attr[:body] = Channel::EmailBuild.html_complete_check( attr[:body] )

        body attr[:body]
      end

      # generate plain part
      attr[:body] = attr[:body].html2text
    end

    # add plain text part
    mail.text_part = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
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
    mail
  end

=begin

  full_html_document_string = Channel::EmailBuild.html_complete_check( html_string )

=end

  def self.html_complete_check(html)
    return html if html =~ /<html>/i

    css = 'font-family:Geneva,Helvetica,Arial,sans-serif; font-size: 12px;'

    html = <<HERE
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>'
  <head>
  <body style="#{css}">#{html}</body>
</html>
HERE

    html
  end
end