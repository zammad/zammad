# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'net/imap'

class Channel::Driver::Imap < Channel::EmailParser

  FETCH_METADATA_TIMEOUT = 2.minutes
  FETCH_MSG_TIMEOUT = 4.minutes
  EXPUNGE_TIMEOUT = 16.minutes

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

example

  params = {
    host: 'outlook.office365.com',
    user: 'xxx@znuny.onmicrosoft.com',
    password: 'xxx',
    keep_on_server: true,
  }

  OR

  params = {
    host: 'imap.gmail.com',
    user: 'xxx@gmail.com',
    password: 'xxx',
    keep_on_server: true,
    auth_type: 'XOAUTH2'
  }

  channel = Channel.last
  instance = Channel::Driver::Imap.new
  result = instance.fetch(params, channel, 'verify')

=end

  def fetch(options, channel, check_type = '', verify_string = '')
    ssl            = true
    starttls       = false
    port           = 993
    keep_on_server = false
    folder         = 'INBOX'
    if options[:keep_on_server] == true || options[:keep_on_server] == 'true'
      keep_on_server = true
    end

    if options.key?(:ssl) && options[:ssl] == false
      ssl  = false
      port = 143
    end

    port = if options.key?(:port) && options[:port].present?
             options[:port].to_i
           elsif ssl == true
             993
           else
             143
           end

    if ssl == true && port != 993
      ssl = false
      starttls = true
    end

    if options[:folder].present?
      folder = options[:folder]
    end

    Rails.logger.info "fetching imap (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl},starttls=#{starttls},folder=#{folder},keep_on_server=#{keep_on_server},auth_type=#{options.fetch(:auth_type, 'LOGIN')})"

    # on check, reduce open_timeout to have faster probing
    check_type_timeout = 45
    if check_type == 'check'
      check_type_timeout = 6
    end

    timeout(check_type_timeout) do
      @imap = ::Net::IMAP.new(options[:host], port, ssl, nil, false)
      if starttls
        @imap.starttls()
      end
    end

    timeout(check_type_timeout) do
      if options[:auth_type].present?
        @imap.authenticate(options[:auth_type], options[:user], options[:password])
      else
        @imap.login(options[:user], options[:password].dup&.force_encoding('ascii-8bit'))
      end
    end

    timeout(check_type_timeout) do
      # select folder
      @imap.select(folder)
    end

    message_ids = timeout(6.minutes) do
      if keep_on_server && check_type != 'check' && check_type != 'verify'
        fetch_unread_message_ids
      else
        fetch_all_message_ids
      end
    end

    # check mode only
    if check_type == 'check'
      Rails.logger.info 'check only mode, fetch no emails'
      content_max_check = 2
      content_messages  = 0

      # check messages
      message_ids.each do |message_id|

        message_meta = nil
        timeout(1.minute) do
          message_meta = @imap.fetch(message_id, ['RFC822.HEADER'])[0]
        end

        # check how many content messages we have, for notice used
        headers = self.class.extract_rfc822_headers(message_meta)
        next if messages_is_verify_message?(headers)
        next if messages_is_ignore_message?(headers)

        content_messages += 1
        break if content_max_check < content_messages
      end
      if content_messages >= content_max_check
        content_messages = message_ids.count
      end

      archive_possible   = false
      archive_check      = 0
      archive_max_check  = 500
      archive_days_range = 14
      archive_week_range = archive_days_range / 7
      message_ids.reverse_each do |message_id|
        message_meta = nil
        timeout(1.minute) do
          message_meta = @imap.fetch(message_id, ['RFC822.HEADER'])[0]
        end

        headers = self.class.extract_rfc822_headers(message_meta)
        next if messages_is_verify_message?(headers)
        next if messages_is_ignore_message?(headers)
        next if headers['Date'].blank?

        archive_check += 1
        break if archive_check >= archive_max_check

        begin
          date = Time.zone.parse(headers['Date'])
        rescue => e
          Rails.logger.error e
          next
        end
        break if date >= Time.zone.now - archive_days_range.days

        archive_possible = true

        break
      end

      disconnect
      return {
        result:             'ok',
        content_messages:   content_messages,
        archive_possible:   archive_possible,
        archive_week_range: archive_week_range,
      }
    end

    # reverse message order to increase performance
    if check_type == 'verify'
      Rails.logger.info "verify mode, fetch no emails #{verify_string}"
      message_ids.reverse!

      # check for verify message
      message_ids.each do |message_id|

        message_meta = nil
        timeout(FETCH_METADATA_TIMEOUT) do
          message_meta = @imap.fetch(message_id, ['RFC822.HEADER'])[0]
        end

        # check if verify message exists
        headers = self.class.extract_rfc822_headers(message_meta)
        subject = headers['Subject']
        next if !subject
        next if !subject.match?(%r{#{verify_string}})

        Rails.logger.info " - verify email #{verify_string} found"
        timeout(600) do
          @imap.store(message_id, '+FLAGS', [:Deleted])
          @imap.expunge()
        end
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
    count_all             = message_ids.count
    count                 = 0
    count_fetched         = 0
    count_max             = 5000
    too_large_messages    = []
    active_check_interval = 20
    result                = 'ok'
    notice                = ''
    message_ids.each do |message_id|
      count += 1

      break if (count % active_check_interval).zero? && channel_has_changed?(channel)
      break if max_process_count_has_reached?(channel, count, count_max)

      Rails.logger.info " - message #{count}/#{count_all}"

      message_meta = nil
      timeout(FETCH_METADATA_TIMEOUT) do
        message_meta = @imap.fetch(message_id, ['RFC822.SIZE', 'FLAGS', 'INTERNALDATE', 'RFC822.HEADER'])[0]
      rescue Net::IMAP::ResponseParseError => e
        raise if e.message.exclude?('unknown token')

        result = 'error'
        notice += <<~NOTICE
          One of your incoming emails could not be imported (#{e.message}).
          Please remove it from your inbox directly
          to prevent Zammad from trying to import it again.
        NOTICE
        Rails.logger.error "Net::IMAP failed to parse message #{message_id}: #{e.message} (#{e.class})"
        Rails.logger.error '(See https://github.com/zammad/zammad/issues/2754 for more details)'
      end

      next if message_meta.nil?

      # ignore verify messages
      next if !messages_is_too_old_verify?(message_meta, count, count_all)

      # ignore deleted messages
      next if deleted?(message_meta, count, count_all)

      # ignore already imported
      next if already_imported?(message_id, message_meta, count, count_all, keep_on_server, channel)

      # delete email from server after article was created
      msg = nil
      begin
        timeout(FETCH_MSG_TIMEOUT) do
          msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
        end
      rescue Timeout::Error => e
        Rails.logger.error "Unable to fetch email from #{count}/#{count_all} from server (#{options[:host]}/#{options[:user]}): #{e.inspect}"
        raise e
      end
      next if !msg

      # do not process too big messages, instead download & send postmaster reply
      too_large_info = too_large?(message_meta)
      if too_large_info
        if Setting.get('postmaster_send_reject_if_mail_too_large') == true
          info = "  - download message #{count}/#{count_all} - ignore message because it's too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
          Rails.logger.info info
          notice += "#{info}\n"
          process_oversized_mail(channel, msg)
        else
          info = "  - ignore message #{count}/#{count_all} - because message is too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB)"
          Rails.logger.info info
          notice += "#{info}\n"
          too_large_messages.push info
          next
        end
      else
        process(channel, msg, false)
      end

      begin
        timeout(FETCH_MSG_TIMEOUT) do
          if keep_on_server
            @imap.store(message_id, '+FLAGS', [:Seen])
          else
            @imap.store(message_id, '+FLAGS', [:Deleted])
          end
        end
      rescue Timeout::Error => e
        Rails.logger.error "Unable to set +FLAGS for email #{count}/#{count_all} on server (#{options[:host]}/#{options[:user]}): #{e.inspect}"
        raise e
      end
      count_fetched += 1
    end

    if !keep_on_server
      begin
        timeout(EXPUNGE_TIMEOUT) do
          @imap.expunge()
        end
      rescue Timeout::Error => e
        Rails.logger.error "Unable to expunge server (#{options[:host]}/#{options[:user]}): #{e.inspect}"
        raise e
      end
    end
    disconnect
    if count.zero?
      Rails.logger.info ' - no message'
    end

    if too_large_messages.present?
      raise too_large_messages.join("\n")
    end

    {
      result:  result,
      fetched: count_fetched,
      notice:  notice,
    }
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
    @imap.sort(['DATE'], filter, 'US-ASCII')
  rescue
    @imap.search(filter)
  end

  def disconnect
    return if !@imap

    timeout(1.minute) do
      @imap.disconnect()
    end
  end

=begin

  Channel::Driver::Imap.streamable?

returns

  true|false

=end

  def self.streamable?
    false
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

  def messages_is_too_old_verify?(message_meta, count, count_all)
    headers = self.class.extract_rfc822_headers(message_meta)
    return true if !messages_is_verify_message?(headers)
    return true if headers['X-Zammad-Verify-Time'].blank?

    begin
      verify_time = Time.zone.parse(headers['X-Zammad-Verify-Time'])
    rescue => e
      Rails.logger.error e
      return true
    end
    return true if verify_time < Time.zone.now - 30.minutes

    Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has a verify message"

    false
  end

  def messages_is_verify_message?(headers)
    return true if headers['X-Zammad-Verify'] == 'true'

    false
  end

  def messages_is_ignore_message?(headers)
    return true if headers['X-Zammad-Ignore'] == 'true'

    false
  end

=begin

check if email is already impoted

  Channel::Driver::IMAP.already_imported?(message_id, message_meta, count, count_all, keep_on_server, channel)

returns

  true|false

=end

  # rubocop:disable Metrics/ParameterLists
  def already_imported?(message_id, message_meta, count, count_all, keep_on_server, channel)
    # rubocop:enable Metrics/ParameterLists
    return false if !keep_on_server

    headers = self.class.extract_rfc822_headers(message_meta)
    retrurn false if !headers

    local_message_id = headers['Message-ID']
    return false if local_message_id.blank?

    local_message_id_md5 = Digest::MD5.hexdigest(local_message_id)
    article = Ticket::Article.where(message_id_md5: local_message_id_md5).order('created_at DESC, id DESC').limit(1).first
    return false if !article

    # verify if message is already imported via same channel, if not, import it again
    ticket = article.ticket
    return false if ticket&.preferences && ticket.preferences[:channel_id].present? && channel.present? && ticket.preferences[:channel_id] != channel[:id]

    timeout(1.minute) do
      @imap.store(message_id, '+FLAGS', [:Seen])
    end
    Rails.logger.info "  - ignore message #{count}/#{count_all} - because message message id already imported"
    true
  end

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

=begin

check if email is to big

  Channel::Driver::IMAP.too_large?(message_meta, count, count_all)

returns

  true|false

=end

  def too_large?(message_meta)
    max_message_size = Setting.get('postmaster_max_size').to_f
    real_message_size = message_meta.attr['RFC822.SIZE'].to_f / 1024 / 1024
    if real_message_size > max_message_size
      return [real_message_size, max_message_size]
    end

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

=begin

check if maximal fetching email count has reached

  Channel::Driver::IMAP.max_process_count_has_reached?(channel, count, count_max)

returns

  true|false

=end

  def max_process_count_has_reached?(channel, count, count_max)
    return false if count < count_max

    Rails.logger.info "Maximal fetched emails (#{count_max}) reached for this interval for Channel with id #{channel.id}."
    true
  end

  def timeout(seconds, &block)
    Timeout.timeout(seconds, &block)
  end

end
