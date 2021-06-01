# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Channel::Filter::AutoResponseCheck

  def self.run(_channel, mail, _transaction_params)

    # if header is available, do not generate auto response
    mail[ :'x-zammad-send-auto-response' ] = false
    mail[ :'x-zammad-is-auto-response' ] = true

    if !mail[ :'x-zammad-article-preferences' ]
      mail[ :'x-zammad-article-preferences' ] = {}
    end
    mail[ :'x-zammad-article-preferences' ]['send-auto-response'] = false
    mail[ :'x-zammad-article-preferences' ]['is-auto-response'] = true

    # do not send an auto response if one of the following headers exists
    return if mail[ :'list-unsubscribe' ] && mail[ :'list-unsubscribe' ] =~ %r{...}
    return if mail[ :'x-loop' ] && mail[ :'x-loop' ] =~ %r{(yes|true)}i
    return if mail[ :precedence ] && mail[ :precedence ] =~ %r{(bulk|list|junk)}i
    return if mail[ :'auto-submitted' ] && mail[ :'auto-submitted' ] =~ %r{auto-(generated|replied)}i
    return if mail[ :'x-auto-response-suppress' ] && mail[ :'x-auto-response-suppress' ] =~ %r{all}i

    # do not send an auto response if sender is system itself
    message_id = mail[ :message_id ]
    if message_id
      fqdn = Setting.get('fqdn')
      return if message_id.match?(%r{@#{Regexp.quote(fqdn)}}i)
    end

    mail[ :'x-zammad-send-auto-response' ] = true
    mail[ :'x-zammad-is-auto-response' ] = false

    mail[ :'x-zammad-article-preferences' ]['send-auto-response'] = true
    mail[ :'x-zammad-article-preferences' ]['is-auto-response'] = false

  end
end
