# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::AutoResponseCheck

  def self.run(_channel, mail)

    # if header is available, do not generate auto response
    mail[ 'x-zammad-send-auto-response'.to_sym ] = false
    mail[ 'x-zammad-is-auto-response'.to_sym ] = true

    if !mail[ 'x-zammad-article-preferences'.to_sym ]
      mail[ 'x-zammad-article-preferences'.to_sym ] = {}
    end
    mail[ 'x-zammad-article-preferences'.to_sym ]['send-auto-response'] = false
    mail[ 'x-zammad-article-preferences'.to_sym ]['is-auto-response'] = true

    # do not send an auto response if one of the following headers exists
    return if mail[ 'list-unsubscribe'.to_sym ] && mail[ 'list-unsubscribe'.to_sym ] =~ /.../
    return if mail[ 'x-loop'.to_sym ] && mail[ 'x-loop'.to_sym ] =~ /(yes|true)/i
    return if mail[ 'precedence'.to_sym ] && mail[ 'precedence'.to_sym ] =~ /(bulk|list|junk)/i
    return if mail[ 'auto-submitted'.to_sym ] && mail[ 'auto-submitted'.to_sym ] =~ /auto-(generated|replied)/i
    return if mail[ 'x-auto-response-suppress'.to_sym ] && mail[ 'x-auto-response-suppress'.to_sym ] =~ /all/i

    # do not send an auto response if sender is system itself
    message_id = mail[ 'message_id'.to_sym ]
    if message_id
      fqdn = Setting.get('fqdn')
      return if message_id.match?(/@#{Regexp.quote(fqdn)}/i)
    end

    mail[ 'x-zammad-send-auto-response'.to_sym ] = true
    mail[ 'x-zammad-is-auto-response'.to_sym ] = false

    mail[ 'x-zammad-article-preferences'.to_sym ]['send-auto-response'] = true
    mail[ 'x-zammad-article-preferences'.to_sym ]['is-auto-response'] = false

  end
end
