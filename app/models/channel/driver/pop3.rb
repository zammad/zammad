# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'net/pop'

class Channel::Driver::Pop3 < Channel::Driver::BaseEmailInbound
  FETCH_COUNT_MAX    = 2_000
  OPEN_TIMEOUT       = 16
  OPEN_CHECK_TIMEOUT = 4
  READ_TIMEOUT       = 45
  READ_CHECK_TIMEOUT = 6

  # Fetches emails from POP3 server
  #
  # @param options [Hash]
  # @option options [String] :folder to fetch emails from
  # @option options [String] :user to login with
  # @option options [String] :password to login with
  # @option options [String] :host
  # @option options [Integer, String] :port
  # @option options [Boolean] :ssl_verify
  # @option options [String] :ssl off to turn off ssl
  # @param channel [Channel]
  #
  # @return [Hash]
  #
  #  {
  #    result: 'ok',
  #    fetched: 123,
  #    notice: 'e. g. message about to big emails in mailbox',
  #  }
  #
  # @example
  #
  #  params = {
  #    user: 'xxx@zammad.onmicrosoft.com',
  #    password: 'xxx',
  #    host: 'example'com'
  #  }
  #
  #  channel = Channel.last
  #  instance = Channel::Driver::Pop3.new
  #  result = instance.fetch(params, channel)
  def fetch(...) # rubocop:disable Lint/UselessMethodDefinition
    # fetch() method is defined in superclass, but options are subclass-specific,
    #   so define it here for documentation purposes.
    super
  end

  def disconnect
    return if !@pop

    @pop.finish
  end

  def setup_connection(options, check: false)
    ssl = true
    if options[:ssl] == 'off'
      ssl = false
    end
    ssl_verify = options.fetch(:ssl_verify, true)

    port = if options.key?(:port) && options[:port].present?
             options[:port].to_i
           elsif ssl == true
             995
           else
             110
           end

    Rails.logger.info "fetching pop3 (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl})"

    @pop = ::Net::POP3.new(options[:host], port)
    # @pop.set_debug_output $stderr

    # on check, reduce open_timeout to have faster probing
    if check
      @pop.open_timeout = OPEN_CHECK_TIMEOUT
      @pop.read_timeout = READ_CHECK_TIMEOUT
    else
      @pop.open_timeout = OPEN_TIMEOUT
      @pop.read_timeout = READ_TIMEOUT
    end

    if ssl
      Certificate::ApplySSLCertificates.ensure_fresh_ssl_context
      @pop.enable_ssl((ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE))
    end
    @pop.start(options[:user], options[:password])
  end

  def messages_iterator(_keep_on_server, _options, reverse: false)
    all = @pop.mails

    all.reverse! if reverse

    [all.first(FETCH_COUNT_MAX), all.size]
  end

  def fetch_single_message(message, count, count_all)
    mail = message.pop

    return MessageResult.new(success: false) if !mail

    message_validator = MessageValidator.new(self.class.extract_headers(mail), mail.size)

    if message_validator.fresh_verify_message?
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has a verify message"

      return MessageResult.new(success: false)
    end

    # do not process too large messages, instead download and send postmaster reply
    if (too_large_info = message_validator.too_large?)
      if Setting.get('postmaster_send_reject_if_mail_too_large') == true
        info = "  - download message #{count}/#{count_all} - ignore message because it's too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
        Rails.logger.info info
        after_action = [:notice, "#{info}\n"]
        process_oversized_mail(@channel, mail)
      else
        info = "  - ignore message #{count}/#{count_all} - because message is too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
        Rails.logger.info info

        return MessageResult.new(success: false, after_action: [:too_large_ignored, "#{info}\n"])
      end
    else
      process(@channel, message.pop, false)
    end

    message.delete

    MessageResult.new(success: true, after_action: after_action)
  end

  def fetch_wrap_up
    disconnect
  end

  def check_single_message(message_id)
    mail = message_id.pop

    return if !mail

    MessageValidator.new(self.class.extract_headers(mail), mail.size)
  end

  def verify_single_message(message_id, verify_regexp)
    mail = message_id.pop
    return if !mail

    # check if verify message exists
    mail.match?(verify_regexp)
  end

  def verify_message_cleanup(message_id)
    message_id.delete
  end

  def self.extract_headers(mail)
    {
      'X-Zammad-Verify'      => mail.include?('X-Zammad-Ignore: true') ? 'true' : 'false',
      'X-Zammad-Ignore'      => mail.include?('X-Zammad-Verify: true') ? 'true' : 'false',
      'X-Zammad-Verify-Time' => mail.match(%r{X-Zammad-Verify-Time:\s(.+?)\s})&.captures&.first,
    }.with_indifferent_access
  end
end
