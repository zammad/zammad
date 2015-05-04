# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'net/imap'

class Channel::IMAP < Channel::EmailParser

  def fetch (channel, check_type = '', verify_string = '')
    ssl  = true
    port = 993
    if channel[:options].key?(:ssl) && channel[:options][:ssl].to_s == 'false'
      ssl  = false
      port = 143
    end

    Rails.logger.info "fetching imap (#{channel[:options][:host]}/#{channel[:options][:user]} port=#{port},ssl=#{ssl})"

    # on check, reduce open_timeout to have faster probing
    timeout = 12
    if check_type == 'check'
      timeout = 6
    end

    Timeout.timeout(timeout) do

      @imap = Net::IMAP.new( channel[:options][:host], port, ssl, nil, false )

    end

    # try LOGIN, if not - try plain
    begin
      @imap.authenticate( 'LOGIN', channel[:options][:user], channel[:options][:password] )
    rescue Exception => e
      if e.to_s !~ /(unsupported\s(authenticate|authentication)\smechanism|not\ssupported)/i
        raise e
      end
      @imap.login( channel[:options][:user], channel[:options][:password] )
    end

    if !channel[:options][:folder] || channel[:options][:folder].empty?
      @imap.select('INBOX')
    else
      @imap.select( channel[:options][:folder] )
    end
    if check_type == 'check'
      Rails.logger.info 'check only mode, fetch no emails'
      disconnect
      return
    elsif check_type == 'verify'
      Rails.logger.info "verify mode, fetch no emails #{verify_string}"
    end

    message_ids = @imap.search(['ALL'])
    count_all   = message_ids.count
    count       = 0

    # reverse message order to increase performance
    if check_type == 'verify'
      message_ids.reverse!
    end

    message_ids.each do |message_id|
      count += 1
      Rails.logger.info " - message #{count.to_s}/#{count_all.to_s}"
      #Rails.logger.info msg.to_s

      # check for verify message
      if check_type == 'verify'
        subject = @imap.fetch(message_id, 'ENVELOPE')[0].attr['ENVELOPE'].subject
        if subject && subject =~ /#{verify_string}/
          Rails.logger.info " - verify email #{verify_string} found"
          @imap.store(message_id, '+FLAGS', [:Deleted])
          @imap.expunge()
          disconnect
          return 'verify ok'
        end
      else

        # delete email from server after article was created
        msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
        if process(channel, msg)
          @imap.store(message_id, '+FLAGS', [:Deleted])
        end
      end
    end
    @imap.expunge()
    disconnect
    if count == 0
      Rails.logger.info ' - no message'
    end
    Rails.logger.info 'done'
  end

  def disconnect
    return if !@imap
    @imap.disconnect()
  end
end
