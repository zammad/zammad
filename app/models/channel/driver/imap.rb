# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'net/imap'

class Channel::Driver::Imap < Channel::Driver::BaseEmailInbound

  FETCH_METADATA_TIMEOUT = 2.minutes
  FETCH_MSG_TIMEOUT      = 4.minutes
  LIST_MESSAGES_TIMEOUT  = 6.minutes
  EXPUNGE_TIMEOUT        = 16.minutes
  DEFAULT_TIMEOUT        = 45.seconds
  CHECK_ONLY_TIMEOUT     = 8.seconds
  FETCH_COUNT_MAX        = 5_000

  # Fetches emails from IMAP server
  #
  # @param options [Hash]
  # @option options [String] :folder to fetch emails from
  # @option options [String] :user to login with
  # @option options [String] :password to login with
  # @option options [String] :host
  # @option options [Integer, String] :port
  # @option options [Boolean] :ssl_verify
  # @option options [String] :ssl off to turn off ssl
  # @option options [String] :auth_type XOAUTH2 for Google/Microsoft365 or fitting authentication type for other
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
  #    user: 'xxx@example.com',
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

  def fetch_all_message_ids
    fetch_message_ids %w[ALL]
  end

  def fetch_unread_message_ids
    fetch_message_ids %w[NOT SEEN]
  rescue
    fetch_message_ids %w[UNSEEN]
  end

  def fetch_message_ids(filter)
    raise if @imap.capabilities.exclude?('SORT')

    {
      result:      @imap.sort(['DATE'], filter, 'US-ASCII'),
      is_fallback: false
    }
  rescue
    {
      result:      @imap.search(filter),
      is_fallback: true # indicates that we can not use a result ordered by date
    }
  end

  def fetch_message_body_key(options)
    # https://github.com/zammad/zammad/issues/4589
    options['host'] == 'imap.mail.me.com' ? 'BODY[]' : 'RFC822'
  end

  def disconnect
    return if !@imap

    Timeout.timeout(1.minute) do
      @imap.disconnect
    end
  end

  # Parses RFC822 header
  # @param [String] RFC822 header text blob
  # @return [Hash<String=>String>]
  def self.parse_rfc822_headers(string)
    array = string
              .gsub("\r\n\t", ' ') # Some servers (e.g. microsoft365) may put attribute value on a separate line and tab it
              .lines(chomp: true)
              .map { |line| line.split(%r{:\s*}, 2).map(&:strip) }

    array.each { |elem| elem.append(nil) if elem.one? }

    Hash[*array.flatten]
  end

  # Parses RFC822 header
  # @param [Net::IMAP::FetchData] fetched message
  # @return [Hash<String=>String>]
  def self.extract_rfc822_headers(message_meta)
    blob = message_meta&.attr&.dig 'RFC822.HEADER'

    return if !blob

    parse_rfc822_headers blob
  end

  private

=begin

check if email is already marked as deleted

  Channel::Driver::IMAP.deleted?(message_meta, count, count_all)

returns

  true|false

=end

  def deleted?(message_meta, count, count_all)
    return false if message_meta.attr['FLAGS'].exclude?(:Deleted)

    Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has already delete flag"
    true
  end

  def setup_connection(options, check: false)
    server_settings = setup_connection_server_settings(options)

    setup_connection_server_log(server_settings)

    Certificate::ApplySSLCertificates.ensure_fresh_ssl_context if server_settings[:ssl_or_starttls]

    # on check, reduce open_timeout to have faster probing
    timeout = check ? CHECK_ONLY_TIMEOUT : DEFAULT_TIMEOUT

    @imap = Timeout.timeout(timeout) do
      Net::IMAP.new(server_settings[:host], port: server_settings[:port], ssl: server_settings[:ssl_settings])
        .tap do |conn|
          next  if server_settings[:ssl_or_starttls] != :starttls

          conn.starttls(verify_mode: server_settings[:ssl_verify] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE)
        end
    end

    Timeout.timeout(timeout) do
      if server_settings[:auth_type].present?
        @imap.authenticate(server_settings[:auth_type], server_settings[:user], server_settings[:password])
      else
        @imap.login(server_settings[:user], server_settings[:password].dup&.force_encoding('ascii-8bit'))
      end
    end

    Timeout.timeout(timeout) do
      # Select folder, but make sure to encode the string value as UTF-7 first (#5480).
      @imap.select(Net::IMAP.encode_utf7(server_settings[:folder]))
    end

    @imap
  end

  def setup_connection_server_log(server_settings)
    settings = [
      "#{server_settings[:host]}/#{server_settings[:user]} port=#{server_settings[:port]}",
      "ssl=#{server_settings[:ssl_or_starttls] == :ssl}",
      "starttls=#{server_settings[:ssl_or_starttls] == :starttls}",
      "folder=#{server_settings[:folder]}",
      "keep_on_server=#{server_settings[:keep_on_server]}",
      "auth_type=#{server_settings.fetch(:auth_type, 'LOGIN')}",
      "ssl_verify=#{server_settings[:ssl_verify]}"
    ]

    Rails.logger.info "fetching imap (#{settings.join(',')}"
  end

  def setup_connection_server_settings(options)
    ssl_or_starttls = setup_connection_ssl_or_starttls(options)
    ssl_verify      = options.fetch(:ssl_verify, true)
    ssl_settings    = setup_connection_ssl_settings(ssl_or_starttls, ssl_verify)

    options
      .slice(:host, :user, :password, :auth_type)
      .merge(
        ssl_or_starttls:,
        ssl_verify:,
        ssl_settings:,
        port:            setup_connection_port(options, ssl_or_starttls),
        folder:          options[:folder].presence || 'INBOX',
        keep_on_server:  ActiveModel::Type::Boolean.new.cast(options[:keep_on_server]),
      )
  end

  def setup_connection_ssl_settings(ssl_or_starttls, ssl_verify)
    if ssl_or_starttls != :ssl
      false
    elsif ssl_verify
      true
    else
      { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    end
  end

  def setup_connection_ssl_or_starttls(options)
    case options[:ssl]
    when 'off'
      false
    when 'starttls'
      :starttls
    else
      :ssl
    end
  end

  def setup_connection_port(options, ssl_or_starttls)
    if options.key?(:port) && options[:port].present?
      options[:port].to_i
    elsif ssl_or_starttls == :ssl
      993
    else
      143
    end
  end

  def fetch_single_message(message_id, count, count_all) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    message_meta = Timeout.timeout(FETCH_METADATA_TIMEOUT) do
      @imap.fetch(message_id, ['RFC822.SIZE', 'FLAGS', 'INTERNALDATE', 'RFC822.HEADER'])[0]
    rescue Net::IMAP::ResponseParseError => e
      raise if e.message.exclude?('unknown token')

      notice += <<~NOTICE
        One of your incoming emails could not be imported (#{e.message}).
        Please remove it from your inbox directly
        to prevent Zammad from trying to import it again.
      NOTICE
      Rails.logger.error "Net::IMAP failed to parse message #{message_id}: #{e.message} (#{e.class})"
      Rails.logger.error '(See https://github.com/zammad/zammad/issues/2754 for more details)'

      return MessageResult.new(success: false, after_action: [:result_error, notice])
    end

    return MessageResult.new(success: false) if message_meta.nil?

    message_validator = MessageValidator.new(self.class.extract_rfc822_headers(message_meta), message_meta.attr['RFC822.SIZE'])

    if message_validator.fresh_verify_message?
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has a verify message"

      return MessageResult.new(success: false)
    end

    # ignore deleted messages
    if deleted?(message_meta, count, count_all)
      return MessageResult.new(success: false)
    end

    # ignore already imported
    if message_validator.already_imported?(@keep_on_server, @channel)
      Timeout.timeout(1.minute) do
        @imap.store(message_id, '+FLAGS', [:Seen])
      end
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message message id already imported"

      return MessageResult.new(success: false)
    end

    # fetch message body
    msg = begin
      Timeout.timeout(FETCH_MSG_TIMEOUT) do
        key = fetch_message_body_key(@options)
        @imap.fetch(message_id, key)[0].attr[key]
      end
    rescue Timeout::Error => e
      Rails.logger.error "Unable to fetch email from #{count}/#{count_all} from server (#{@options[:host]}/#{@options[:user]}): #{e.inspect}"
      raise e
    end

    if !msg
      return MessageResult.new(success: false)
    end

    # do not process too big messages, instead download & send postmaster reply
    if (too_large_info = message_validator.too_large?)
      if Setting.get('postmaster_send_reject_if_mail_too_large') == true
        info = "  - download message #{count}/#{count_all} - ignore message because it's too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
        Rails.logger.info info
        after_action = [:notice, "#{info}\n"]
        process_oversized_mail(@channel, msg)
      else
        info = "  - ignore message #{count}/#{count_all} - because message is too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
        Rails.logger.info info

        return MessageResult.new(success: false, after_action: [:too_large_ignored, "#{info}\n"])
      end
    else
      process(@channel, msg, false)
    end

    # delete email from server after article was created
    begin
      Timeout.timeout(FETCH_MSG_TIMEOUT) do
        if @keep_on_server
          @imap.store(message_id, '+FLAGS', [:Seen])
        else
          @imap.store(message_id, '+FLAGS', [:Deleted])
        end
      end
    rescue Timeout::Error => e
      Rails.logger.error "Unable to set +FLAGS for email #{count}/#{count_all} on server (#{@options[:host]}/#{@options[:user]}): #{e.inspect}"
      raise e
    end

    MessageResult.new(success: true, after_action: after_action)
  end

  def messages_iterator(keep_on_server, _options, reverse: false)
    message_ids_result = Timeout.timeout(LIST_MESSAGES_TIMEOUT) do
      if keep_on_server
        fetch_unread_message_ids
      else
        fetch_all_message_ids
      end
    end

    ids = message_ids_result[:result]

    ids.reverse! if reverse

    [ids.first(FETCH_COUNT_MAX), ids.count]
  end

  def fetch_wrap_up
    if !@keep_on_server
      begin
        Timeout.timeout(EXPUNGE_TIMEOUT) do
          @imap.expunge
        end
      rescue Timeout::Error => e
        Rails.logger.error "Unable to expunge server (#{@options[:host]}/#{@options[:user]}): #{e.inspect}"
        raise e
      end
    end

    disconnect
  end

  def check_single_message(message_id)
    message_meta = Timeout.timeout(FETCH_METADATA_TIMEOUT) do
      @imap.fetch(message_id, ['RFC822.HEADER'])[0]
    end

    MessageValidator.new(self.class.extract_rfc822_headers(message_meta))
  end

  def verify_single_message(message_id, verify_string)
    message_meta = Timeout.timeout(FETCH_METADATA_TIMEOUT) do
      @imap.fetch(message_id, ['RFC822.HEADER'])[0]
    end

    # check if verify message exists
    headers = self.class.extract_rfc822_headers(message_meta)

    headers['Subject']&.match?(%r{#{verify_string}})
  end

  def verify_message_cleanup(message_id)
    Timeout.timeout(EXPUNGE_TIMEOUT) do
      @imap.store(message_id, '+FLAGS', [:Deleted])
      @imap.expunge
    end
  end
end
