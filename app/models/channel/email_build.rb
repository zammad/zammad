# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'mail'

module Channel::EmailBuild

=begin

  mail = Channel::EmailBuild.build(
    from: 'sender@example.com',
    to: 'recipient@example.com',
    body: 'somebody with some text',
    content_type: 'text/plain',
  )

=end

  def self.build(attr, notification = false)
    mail = Mail.new

    # set organization
    organization = Setting.get('organization')
    if organization
      mail['Organization'] = organization.to_s
    end

    # notification
    if notification
      attr['X-Loop']                   = 'yes'
      attr['Precedence']               = 'bulk'
      attr['Auto-Submitted']           = 'auto-generated'
      attr['X-Auto-Response-Suppress'] = 'All'
    end

    #attr['X-Powered-BY'] = 'Zammad - Support/Helpdesk (http://www.zammad.org/)'
    attr['X-Mailer'] = 'Zammad Mail Service (1.x)'

    # set headers
    attr.each do |key, value|
      next if key.to_s == 'attachments'
      next if key.to_s == 'body'
      next if key.to_s == 'content_type'
      mail[key.to_s] = if value && value.class != Array
                         value.to_s
                       else
                         value
                       end
    end

    # add html part
    if attr[:content_type] && attr[:content_type] == 'text/html'
      html_alternative = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'

        # complete check
        html_document = Channel::EmailBuild.html_complete_check(attr[:body])

        body html_document
      end

      # generate plain part
      attr[:body] = attr[:body].html2text
    end

    # add plain text part
    text_alternative = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      body attr[:body]
    end

    # build email without any attachments
    if !html_alternative && ( !attr[:attachments] || attr[:attachments].empty? )
      mail.content_type 'text/plain; charset=UTF-8'
      mail.body attr[:body]
      return mail
    end

    # build email with attachments
    alternative_bodies = Mail::Part.new { content_type 'multipart/alternative' }
    alternative_bodies.add_part text_alternative

    if html_alternative
      html_container = Mail::Part.new { content_type 'multipart/related' }
      html_container.add_part html_alternative
      alternative_bodies.add_part html_container

      # place to add inline attachments related to html alternative
    end

    mail.add_part alternative_bodies

    # add attachments
    if attr[:attachments]
      attr[:attachments].each do |attachment|
        if attachment.class == Hash
          attachment['content-id'] = nil
          mail.attachments[ attachment[:filename] ] = attachment
        else
          mail.attachments[attachment.filename] = {
            :content_type => attachment.preferences['Content-Type'],
            :mime_type    => attachment.preferences['Mime-Type'],
            :content      => attachment.content,
            'content-id'  => nil,
          }
        end
      end
    end
    mail
  end

=begin

Check if string is a complete html document. If not, add head and css styles.

  full_html_document_string = Channel::EmailBuild.html_complete_check(html_string)

=end

  def self.html_complete_check(html)

    # apply mail client fixes
    html = Channel::EmailBuild.html_mail_client_fixes(html)

    return html if html =~ /<html>/i

    css = "font-family:'Helvetica Neue', Helvetica, Arial, Geneva, sans-serif; font-size: 12px;"

    html = <<HERE
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <style type="text/css">
    body {
      width:90% !important;
      -webkit-text-size-adjust:90%;
      -ms-text-size-adjust:90%;
      #{css};
    }
    img {
      outline:none; text-decoration:none; -ms-interpolation-mode: bicubic;
    }
    a img {
      border:none;
    }
    table td {
      border-collapse: collapse;
    }
    table {
      border-collapse: collapse; mso-table-lspace:0pt; mso-table-rspace:0pt;
    }
    p, table, div, td {
      max-width: 600px;
    }
    p {
      margin: 0;
    }
    blockquote {
      border-left: 2px solid blue;
      margin: 0px;
      padding: 8px 12px 8px 12px;
    }
    pre {
      margin: 0px;
      padding: 8px 12px 8px 12px;
    }
    </style>
  <head>
  <body style="#{css}">#{html}</body>
</html>
HERE

    html
  end

=begin

Add/change markup to display html in any mail client nice.

  html_string_with_fixes = Channel::EmailBuild.html_mail_client_fixes(html_string)

=end

  def self.html_mail_client_fixes(html)

    # https://github.com/martini/zammad/issues/165
    html.gsub('<blockquote type="cite">', '<blockquote type="cite" style="border-left: 2px solid blue; margin: 0px; padding: 8px 12px 8px 12px;">')

  end

end
