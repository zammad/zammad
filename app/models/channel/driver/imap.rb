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


  def connect(options, timeout=45)
    ssl            = true
    starttls       = false
    port           = 993
    keep_on_server = false
    folder         = 'INBOX'
    if options[:keep_on_server] == true || options[:keep_on_server] == 'true'
      keep_on_server = 1
    elsif options[:keep_on_server] == 2 || options[:keep_on_server] == '2'
      keep_on_server = 2
    end

    ssl = options.key?(:ssl) && options[:ssl] == true

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

    Rails.logger.info "connecting imap (#{options[:host]}/#{options[:user]} port=#{port},ssl=#{ssl},starttls=#{starttls},folder=#{folder},keep_on_server=#{keep_on_server})"

    Timeout.timeout(timeout) do
      @imap = Net::IMAP.new(options[:host], port, ssl, nil, false)
      if starttls
        @imap.starttls()
      end
    end

    @imap.login(options[:user], options[:password])

    # select folder in read only mode, when setting flags, the user must actually select the folder, this is safer
    @imap.examine(folder)

    @imap
  end


  def place_reply(options, mail)

    if options[:keep_on_server] == true || options[:keep_on_server] == 'true'
      keep_on_server = 1
    elsif options[:keep_on_server] == 2 || options[:keep_on_server] == '2'
      keep_on_server = 2
    end

    return if !keep_on_server

    return if options[:sent_folder].to_s.empty?
    target_mailbox = options[:sent_folder]
    
    main_folder = "INBOX"
    if options[:folder].present?
      main_folder = options[:folder]
    end

    @imap = connect(options)

    #@imap.create(target_mailbox) if !@imap.list('', target_mailbox)
    @imap.append(target_mailbox, mail.to_s, [:Seen])

    @imap.select(main_folder)
    mail.header.fields.each do |field|
      if field.name=='In-Reply-To'
        search_message_id = field.value
        replied_message_id = @imap.search(["HEADER", "Message-ID", search_message_id])[0]	
        
        if !replied_message_id.nil?
          @imap.store(replied_message_id, '+FLAGS', [:Answered])
        end
        break
      end
    end

    disconnect
    return

  end 
  

  def fetch(options, channel, check_type = '', verify_string = '')

    # on check, reduce open_timeout to have faster probing
    timeout = 45
    if check_type == 'check'
      timeout = 6
    end

    if options[:keep_on_server] == true || options[:keep_on_server] == 'true'
      keep_on_server = 1
    elsif options[:keep_on_server] == 2 || options[:keep_on_server] == '2'
      keep_on_server = 2
    end

    main_folder = "INBOX"
    if options[:folder].present?
      main_folder = options[:folder]
    end
    
    if options[:sent_folder].present?
      sent_folder = options[:sent_folder]
    end

    @imap = connect(options, timeout)

    # sort messages by date on server (if not supported), if not fetch messages via search (first in, first out)
    if check_type == 'check' || check_type == 'verify'
      filter = ['ALL']
      begin
        message_ids = @imap.sort(['DATE'], filter, 'US-ASCII')
      rescue
        message_ids = @imap.search(filter)
      end
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
        @imap.select(main_folder)
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


    # fetch regular messages from both folders if defined
    
    count_fetched = 0
    notice = ''

    [main_folder, sent_folder].each do |folder|
      
      continue if folder.to_s.empty?
      
      if keep_on_server != 2
        #@imap.select(folder)
        @imap.examine(folder)
      else
        @imap.examine(folder)
      end


      filter = ['ALL']
      if keep_on_server==1 
        filter = %w[NOT SEEN]
      elsif keep_on_server==2 && channel.preferences && channel.preferences[:last_fetch]
        filter = ['SINCE', Net::IMAP.format_date(channel.preferences[:last_fetch] - 2.days)]
      end

      message_ids = @imap.search(filter)

      count_all     = message_ids.count
      count         = 0
      
      message_ids.each do |message_id|
        count += 1
        Rails.logger.info " - message #{count}/#{count_all} in #{folder}"

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
        next if already_imported?(message_id, message_meta, count, count_all, keep_on_server,channel)

        # delete email from server after article was created
        msg = @imap.fetch(message_id, 'RFC822')[0].attr['RFC822']
        next if !msg
        process(channel, msg, false)
        if !keep_on_server
          @imap.store(message_id, '+FLAGS', [:Deleted])
        elsif keep_on_server == 1
          @imap.store(message_id, '+FLAGS', [:Seen])
        end
        count_fetched += 1
      end
      if !keep_on_server
        @imap.expunge()
      end
      if count.zero?
        Rails.logger.info " - no messages in #{folder}"
      end
    end

    disconnect
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

  # rubocop:disable Metrics/ParameterLists
  def already_imported?(message_id, message_meta, count, count_all, keep_on_server, channel)
    # rubocop:enable Metrics/ParameterLists
    return false if !keep_on_server
    return false if !message_meta.attr
    return false if !message_meta.attr['ENVELOPE']
    local_message_id = message_meta.attr['ENVELOPE'].message_id
    return false if local_message_id.blank?
    local_message_id_md5 = Digest::MD5.hexdigest(local_message_id)
    article = Ticket::Article.where(message_id_md5: local_message_id_md5).order('created_at DESC, id DESC').limit(1).first
    return false if !article

    # verify if message is already imported via same channel, if not, import it again
    ticket = article.ticket
    #if ticket&.preferences && ticket.preferences[:channel_id].present? && channel.present?
    #  return false if ticket.preferences[:channel_id] != channel[:id]
    #end

    if keep_on_server == 1
      @imap.store(message_id, '+FLAGS', [:Seen])
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message message id already imported"
    end

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
