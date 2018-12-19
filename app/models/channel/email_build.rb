# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
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

    attr['X-Powered-By'] = 'Zammad - Helpdesk/Support (https://zammad.org/)'
    attr['X-Mailer'] = 'Zammad Mail Service'

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
    if !html_alternative && attr[:attachments].blank?
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

      # place to add inline attachments related to html alternative
      attr[:attachments]&.each do |attachment|
        next if attachment.class == Hash
        next if attachment.preferences['Content-ID'].blank?

        attachment = Mail::Part.new do
          content_type attachment.preferences['Content-Type']
          content_id "<#{attachment.preferences['Content-ID']}>"
          content_disposition attachment.preferences['Content-Disposition'] || 'inline'
          content_transfer_encoding 'binary'
          body attachment.content.force_encoding('BINARY')
        end
        html_container.add_part attachment
      end
      alternative_bodies.add_part html_container
    end

    mail.add_part alternative_bodies

    # add attachments
    attr[:attachments]&.each do |attachment|
      if attachment.class == Hash
        attachment['content-id'] = nil
        mail.attachments[attachment[:filename]] = attachment
      else
        next if attachment.preferences['Content-ID'].present?

        filename = attachment.filename
        encoded_filename = Mail::Encodings.decode_encode filename, :encode
        disposition = attachment.preferences['Content-Disposition'] || 'attachment'
        content_type = attachment.preferences['Content-Type'] || attachment.preferences['Mime-Type'] || 'application/octet-stream'
        mail.attachments[attachment.filename] = {
          content_disposition: "#{disposition}; filename=\"#{encoded_filename}\"",
          content_type:        "#{content_type}; filename=\"#{encoded_filename}\"",
          content:             attachment.content
        }
      end
    end
    mail
  end

=begin

  quoted_in_one_line = Channel::EmailBuild.recipient_line('Somebody @ "Company"', 'some.body@example.com')

returns

  '"Somebody @ \"Company\"" <some.body@example.com>'

=end

  def self.recipient_line(realname, email)
    return "#{realname} <#{email}>" if realname.match?(/^[A-z]+$/i)

    "\"#{realname.gsub('"', '\"')}\" <#{email}>"
  end

=begin

Check if string is a complete html document. If not, add head and css styles.

  full_html_document_string = Channel::EmailBuild.html_complete_check(html_string)

=end

  def self.html_complete_check(html)

    # apply mail client fixes
    html = Channel::EmailBuild.html_mail_client_fixes(html)

    return html if html.match?(/<html>/i)

    html_email_body = File.read(Rails.root.join('app', 'views', 'mailer', 'application_wrapper.html.erb').to_s)

    html_email_body.gsub!('###html_email_css_font###', Setting.get('html_email_css_font'))

    # use block form because variable html could contain backslashes and e. g. '\1' that
    # must not be handled as back-references for regular expressions
    html_email_body.sub('###html###') { html }
  end

=begin

Add/change markup to display html in any mail client nice.

  html_string_with_fixes = Channel::EmailBuild.html_mail_client_fixes(html_string)

=end

  def self.html_mail_client_fixes(html)

    # https://github.com/martini/zammad/issues/165
    new_html = html.gsub('<blockquote type="cite">', '<blockquote type="cite" style="border-left: 2px solid blue; margin: 0 0 16px; padding: 8px 12px 8px 12px;">')
    new_html.gsub!(/<p>/mxi, '<p style="margin: 0;">')
    new_html.gsub!(%r{</?hr>}mxi, '<hr style="margin-top: 6px; margin-bottom: 6px; border: 0; border-top: 1px solid #dfdfdf;">')
    new_html
  end

end
