# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'mail'

class Channel::EmailBuild

=begin

  backend = Channel::EmailBuild.new
  mail = backend.send(
    :from => 'sender@example.com',
    :to   => 'recipient@example.com',
    :body => 'somebody with some text',
  )

=end

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
        body attr[:body]
      end

      # generate plain part
      attr[:body] = html2text( attr[:body] )
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

  private

    # from https://gist.github.com/petrblaho/657856
    def html2text(html)
      text = html.
        gsub(/(&nbsp;|\n|\s)+/im, ' ').squeeze(' ').strip.
        gsub(/<([^\s]+)[^>]*(src|href)=\s*(.?)([^>\s]*)\3[^>]*>\4<\/\1>/i, '\4')

      links = []
      linkregex = /<[^>]*(src|href)=\s*(.?)([^>\s]*)\2[^>]*>\s*/i
      while linkregex.match(text)
        links << $~[3]
        text.sub!(linkregex, "[#{links.size}]")
      end

      text = CGI.unescapeHTML(
        text.
          gsub(/<(script|style)[^>]*>.*<\/\1>/im, '').
          gsub(/<!--.*-->/m, '').
          gsub(/<hr(| [^>]*)>/i, "___\n").
          gsub(/<li(| [^>]*)>/i, "\n* ").
          gsub(/<blockquote(| [^>]*)>/i, '> ').
          gsub(/<(br)(| [^>]*)>/i, "\n").
          gsub(/<(\/h[\d]+|p)(| [^>]*)>/i, "\n\n").
          gsub(/<[^>]*>/, '')
      ).lstrip.gsub(/\n[ ]+/, "\n") + "\n"

      for i in (0...links.size).to_a
        text = text + "\n  [#{i+1}] <#{CGI.unescapeHTML(links[i])}>" unless links[i].nil?
      end
      links = nil
      text
    end
end