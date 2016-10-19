# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

require 'net/imap'

class Channel::Driver::Imap < Channel::EmailParser

  def fetchable?(_channel)
    true
  end

=begin

fetch emails from IMAP account

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok',
    fetched: 123,
    notice: 'e. g. message about to big emails in mailbox',
  }

check if connect to IMAP account is possible, return count of mails in mailbox

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'check')

returns

  {
    result: 'ok',
    content_messages: 123,
  }

verify IMAP account, check if search email is in there

  instance = Channel::Driver::Imap.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok', # 'verify not ok'
  }

=end

  def fetch (options, channel, check_type = '', verify_string = '')
    ssl  = true
    port = 993
    if options.key?(:ssl) && options[:ssl].to_s == 'false'
      ssl  = false
      port = 143
    end

    Rails.logger.info "fetching imap (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl})"

    # on check, reduce open_timeout to have faster probing
    timeout = 12
    if check_type == 'check'
      timeout = 6
    end

    Timeout.timeout(timeout) do
      @imap = Net::IMAP.new(options[:host], port, ssl, nil, false)
    end

    # try LOGIN, if not - try plain
    begin
      @imap.authenticate('LOGIN', options[:user], options[:password])
    rescue => e
      if e.to_s !~ /(unsupported\s(authenticate|authentication)\smechanism|not\ssupported)/i
        raise e
      end
      @imap.login(options[:user], options[:password])
    end

    # select folder
    if !options[:folder] || options[:folder].empty?
      @imap.select('INBOX')
    else
      @imap.select(options[:folder])
    end

    begin
      message_ids = @imap.sort(['DATE'], ['ALL'], 'US-ASCII')
    rescue => e
      Rails.logger.error "Unable to use imap sort: #{e.inspect}, use imap search now"
      message_ids = @imap.search(['ALL'])
    end

    # check mode only
    if check_type == 'check'
      Rails.logger.info 'check only mode, fetch no emails'
      content_max_check = 2
      content_messages  = 0

      # check messages
      message_ids.each do |message_id|

        message_meta = @imap.fetch(message_id, ['RFC822.HEADER'])[0].attr

        # check how many content messages we have, for notice used
        header = message_meta['RFC822.HEADER']
        if header && header !~ /x-zammad-ignore/i
          content_messages += 1
          break if content_max_check < content_messages
        end
      end
      if content_messages >= content_max_check
        content_messages = message_ids.count
      end
      disconnect
      return {
        result: 'ok',
        content_messages: content_messages,
      }
    end

    # reverse message order to increase performance
    if check_type == 'verify'
      Rails.logger.info "verify mode, fetch no emails #{verify_string}"
      message_ids.reverse!

      # check for verify message
      message_ids.each do |message_id|

        message_meta = @imap.fetch(message_id, ['ENVELOPE'])[0].attr

        # check if verify message exists
        subject = message_meta['ENVELOPE'].subject
        next if !subject
        next if subject !~ /#{verify_string}/
        Rails.logger.info " - verify email #{verify_string} found"
        @imap.store(message_id, '+FLAGS', [:Deleted])
        @imap.expunge()
        disconnect
        return {
          result: 'ok',
        }
      end

      disconnect
      return {
        result: 'verify not ok',
      }
    end

    # fetch regular messages
    count_all     = message_ids.count
    count         = 0
    count_fetched = 0
    notice        = ''
    message_ids.each do |message_id|
      count += 1
      Rails.logger.info " - message #{count}/#{count_all}"
      #Rails.logger.info msg.to_s

      message_meta = @imap.fetch(message_id, ['RFC822.SIZE', 'FLAGS', 'INTERNALDATE'])[0]

      # ignore to big messages
      max_message_size = Setting.get('postmaster_max_size').to_f
      real_message_size = message_meta.attr['RFC822.SIZE'].to_f / 1024 / 1024
      if real_message_size > max_message_size
        info = "  - ignore message #{count}/#{count_all} - because message is too big (is:#{real_message_size} MB/max:#{max_message_size} MB)"
        Rails.logger.info info
        notice += "#{info}\n"
        next
      end

      # ignore deleted messages
      if message_meta.attr['FLAGS'].include?(:Deleted)
        Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has already delete flag"
        next
      end

      # delete email from server after article was created
      msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      next if !msg
      if process(channel, msg)
        @imap.store(message_id, '+FLAGS', [:Deleted])
        count_fetched += 1
      end
    end
    @imap.expunge()
    disconnect
    if count.zero?
      Rails.logger.info ' - no message'
    end
    Rails.logger.info 'done'
    {
      result: 'ok',
      fetched: count_fetched,
      notice: notice,
    }
  end

  def disconnect
    return if !@imap
    @imap.disconnect()
  end
end
