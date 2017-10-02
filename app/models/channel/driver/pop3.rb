# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

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

    @pop = Net::POP3.new(options[:host], port)
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
        if mail !~ /x-zammad-ignore/i
          content_messages += 1
          break if content_max_check < content_messages
        end
      end
      if content_messages >= content_max_check
        content_messages = mails.count
      end
      disconnect
      return {
        result: 'ok',
        content_messages: content_messages,
      }
    end

    # reverse message order to increase performance
    if check_type == 'verify'
      Rails.logger.info 'verify mode, fetch no emails'
      mails.reverse!

      # check for verify message
      mails.each do |m|
        mail = m.pop
        next if !mail

        # check if verify message exists
        next if mail !~ /#{verify_string}/
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
    count_all     = mails.size
    count         = 0
    count_fetched = 0
    notice        = ''
    mails.each do |m|
      count += 1
      Rails.logger.info " - message #{count}/#{count_all}"
      mail = m.pop
      next if !mail

      # ignore to big messages
      max_message_size = Setting.get('postmaster_max_size').to_f
      real_message_size = mail.size.to_f / 1024 / 1024
      if real_message_size > max_message_size
        info = "  - ignore message #{count}/#{count_all} - because message is too big (is:#{real_message_size} MB/max:#{max_message_size} MB)"
        Rails.logger.info info
        notice += "#{info}\n"
        next
      end

      # delete email from server after article was created
      process(channel, m.pop, false)
      m.delete
      count_fetched += 1
    end
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

  def disconnect
    return if !@pop
    @pop.finish
  end

end
