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

example

  params = {
    host: 'outlook.office365.com',
    user: 'xxx@znuny.onmicrosoft.com',
    password: 'xxx',
    keep_on_server: true,
  }
  channel = Channel.last
  instance = Channel::Driver::Imap.new
  result = instance.fetch(params, channel, 'verify')

=end

  def fetch(options, channel, check_type = '', verify_string = '')
    ssl            = true
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
    if options.key?(:port) && options[:port].present?
      port = options[:port]

      # disable ssl for non ssl ports
      if port == 143 && !options.key?(:ssl)
        ssl = false
      end
    end
    if options[:folder].present?
      folder = options[:folder]
    end

    Rails.logger.info "fetching imap (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl},folder=#{folder},keep_on_server=#{keep_on_server})"

    # on check, reduce open_timeout to have faster probing
    timeout = 45
    if check_type == 'check'
      timeout = 6
    end

    Timeout.timeout(timeout) do
      @imap = Net::IMAP.new(options[:host], port, ssl, nil, false)
    end

    @imap.login(options[:user], options[:password])

    # select folder
    @imap.select(folder)

    # sort messages by date on server (if not supported), if not fetch messages via search (first in, first out)
    filter = ['ALL']
    if keep_on_server && check_type != 'check' && check_type != 'verify'
      filter = %w(NOT SEEN)
    end
    begin
      message_ids = @imap.sort(['DATE'], filter, 'US-ASCII')
    rescue
      message_ids = @imap.search(filter)
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

      message_meta = @imap.fetch(message_id, ['RFC822.SIZE', 'ENVELOPE', 'FLAGS', 'INTERNALDATE'])[0]

      # ignore to big messages
      info = too_big?(message_meta, count, count_all)
      if info
        notice += "#{info}\n"
        next
      end

      # ignore deleted messages
      next if deleted?(message_meta, count, count_all)

      # ignore already imported
      next if already_imported?(message_id, message_meta, count, count_all, keep_on_server)

      # delete email from server after article was created
      msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
      next if !msg
      process(channel, msg, false)
      if !keep_on_server
        @imap.store(message_id, '+FLAGS', [:Deleted])
      else
        @imap.store(message_id, '+FLAGS', [:Seen])
      end
      count_fetched += 1
    end
    if !keep_on_server
      @imap.expunge()
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

  def disconnect
    return if !@imap
    @imap.disconnect()
  end

=begin

  Channel::Driver::Imap.streamable?

returns

  true|false

=end

  def self.streamable?
    false
  end

  private

  def already_imported?(message_id, message_meta, count, count_all, keep_on_server)
    return false if !keep_on_server
    return false if !message_meta.attr
    return false if !message_meta.attr['ENVELOPE']
    local_message_id = message_meta.attr['ENVELOPE'].message_id
    return false if local_message_id.blank?
    local_message_id_md5 = Digest::MD5.hexdigest(local_message_id)
    article = Ticket::Article.where(message_id_md5: local_message_id_md5).order('created_at DESC, id DESC').limit(1).first
    return false if !article
    @imap.store(message_id, '+FLAGS', [:Seen])
    Rails.logger.info "  - ignore message #{count}/#{count_all} - because message message id already imported"
    true
  end

  def deleted?(message_meta, count, count_all)
    return false if !message_meta.attr['FLAGS'].include?(:Deleted)
    Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has already delete flag"
    true
  end

  def too_big?(message_meta, count, count_all)
    max_message_size = Setting.get('postmaster_max_size').to_f
    real_message_size = message_meta.attr['RFC822.SIZE'].to_f / 1024 / 1024
    if real_message_size > max_message_size
      info = "  - ignore message #{count}/#{count_all} - because message is too big (is:#{real_message_size} MB/max:#{max_message_size} MB)"
      Rails.logger.info info
      return info
    end
    false
  end

end
