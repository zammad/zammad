# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'net/pop'

class Channel::Driver::Pop3 < Channel::EmailParser

=begin

fetch emails from Pop3 account

  instance = Channel::Driver::Pop3.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok',
    fetched: 123,
    notice: 'e. g. message about to big emails in mailbox',
  }

check if connect to Pop3 account is possible, return count of mails in mailbox

  instance = Channel::Driver::Pop3.new
  result = instance.fetch(params[:inbound][:options], channel, 'check')

returns

  {
    result: 'ok',
    content_messages: 123,
  }

verify Pop3 account, check if search email is in there

  instance = Channel::Driver::Pop3.new
  result = instance.fetch(params[:inbound][:options], channel, 'verify', subject_looking_for)

returns

  {
    result: 'ok', # 'verify not ok'
  }

=end

  def fetch(options, channel, check_type = '', verify_string = '')
    ssl  = true
    port = 995
    if options.key?(:ssl) && options[:ssl] == false
      ssl  = false
      port = 110
    end
    if options.key?(:port) && options[:port].present?
      port = options[:port]

      # disable ssl for non ssl ports
      if port == 110 && !options.key?(:ssl)
        ssl = false
      end
    end

    Rails.logger.info "fetching pop3 (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl})"

    @pop = ::Net::POP3.new(options[:host], port)
    #@pop.set_debug_output $stderr

    # on check, reduce open_timeout to have faster probing
    @pop.open_timeout = 16
    @pop.read_timeout = 45
    if check_type == 'check'
      @pop.open_timeout = 4
      @pop.read_timeout = 6
    end

    if ssl
      @pop.enable_ssl(OpenSSL::SSL::VERIFY_NONE)
    end
    @pop.start(options[:user], options[:password])

    mails = @pop.mails

    if check_type == 'check'
      Rails.logger.info 'check only mode, fetch no emails'
      content_max_check = 2
      content_messages  = 0

      # check messages
      mails.each do |m|
        mail = m.pop
        next if !mail

        # check how many content messages we have, for notice used
        if !mail.match?(%r{(X-Zammad-Ignore: true|X-Zammad-Verify: true)})
          content_messages += 1
          break if content_max_check < content_messages
        end
      end
      if content_messages >= content_max_check
        content_messages = mails.count
      end
      disconnect
      return {
        result:           'ok',
        content_messages: content_messages,
      }
    end

    # reverse message order to increase performance
    if check_type == 'verify'
      Rails.logger.info 'verify mode, fetch no emails'
      mails.reverse!

      # check for verify message
      mails.first(2000).each do |m|
        mail = m.pop
        next if !mail

        # check if verify message exists
        next if !mail.match?(%r{#{verify_string}})

        Rails.logger.info " - verify email #{verify_string} found"
        m.delete
        disconnect
        return {
          result: 'ok',
        }
      end

      return {
        result: 'verify not ok',
      }
    end

    # fetch regular messages
    count_all             = mails.size
    count                 = 0
    count_fetched         = 0
    too_large_messages    = []
    active_check_interval = 20
    notice                = ''
    mails.first(2000).each do |m|
      count += 1

      break if (count % active_check_interval).zero? && channel_has_changed?(channel)

      Rails.logger.info " - message #{count}/#{count_all}"
      mail = m.pop
      next if !mail

      # ignore verify messages
      if mail.match?(%r{(X-Zammad-Ignore: true|X-Zammad-Verify: true)}) && mail =~ %r{X-Zammad-Verify-Time:\s(.+?)\s}
        begin
          verify_time = Time.zone.parse($1)
          if verify_time > Time.zone.now - 30.minutes
            info = "  - ignore message #{count}/#{count_all} - because it's a verify message"
            Rails.logger.info info
            next
          end
        rescue => e
          Rails.logger.error e
        end
      end

      # do not process too large messages, instead download and send postmaster reply
      max_message_size = Setting.get('postmaster_max_size').to_f
      real_message_size = mail.size.to_f / 1024 / 1024
      if real_message_size > max_message_size
        if Setting.get('postmaster_send_reject_if_mail_too_large') == true
          info = "  - download message #{count}/#{count_all} - ignore message because it's too large (is:#{real_message_size} MB/max:#{max_message_size} MB)"
          Rails.logger.info info
          notice += "#{info}\n"
          process_oversized_mail(channel, mail)
        else
          info = "  - ignore message #{count}/#{count_all} - because message is too large (is:#{real_message_size} MB/max:#{max_message_size} MB)"
          Rails.logger.info info
          notice += "#{info}\n"
          too_large_messages.push info
          next
        end

      # delete email from server after article was created
      else
        process(channel, m.pop, false)
      end

      m.delete
      count_fetched += 1
    end
    disconnect
    if count.zero?
      Rails.logger.info ' - no message'
    end

    if too_large_messages.present?
      raise too_large_messages.join("\n")
    end

    Rails.logger.info 'done'
    {
      result:  'ok',
      fetched: count_fetched,
      notice:  notice,
    }
  end

=begin

  instance = Channel::Driver::Pop3.new
  instance.fetchable?(channel)

=end

  def fetchable?(_channel)
    true
  end

=begin

  Channel::Driver::Pop3.streamable?

returns

  true|false

=end

  def self.streamable?
    false
  end

=begin

check if channel config has changed

  Channel::Driver::IMAP.channel_has_changed?(channel)

returns

  true|false

=end

  def channel_has_changed?(channel)
    current_channel = Channel.find_by(id: channel.id)
    if !current_channel
      Rails.logger.info "Channel with id #{channel.id} is deleted in the meantime. Stop fetching."
      return true
    end
    return false if channel.updated_at == current_channel.updated_at

    Rails.logger.info "Channel with id #{channel.id} has changed. Stop fetching."
    true
  end

  def disconnect
    return if !@pop

    @pop.finish
  end

end
