# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::MicrosoftGraphInbound < Channel::Driver::BaseEmailInbound

  # Fetches emails from Microsfot 365 account via Graph API
  #
  # @param options [Hash]
  # @option options [Bool, String] :keep_on_server
  # @option options [String] :folder_id to fetch emails from
  # @option options [String] :user to login with
  # @option options [String] :shared_mailbox optional
  # @option options [String] :password Graph API access token
  # @option options [String] :auth_type must be XOAUTH2
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
  #    shared_mailbox: 'yyy@zammad.onmicrosoft.com',
  #    keep_on_server: true,
  #    auth_type: 'XOAUTH2'
  #  }
  #
  #  channel = Channel.last
  #  instance = Channel::Driver::MicrosoftGraphInbound.new
  #  result = instance.fetch(params, channel)
  def fetch(...) # rubocop:disable Lint/UselessMethodDefinition
    # fetch() method is defined in superclass, but options are subclass-specific,
    #   so define it here for documentation purposes.
    super
  end

  # Checks if mailbox has any messages.
  # It does not check if email is Zammad verification email or not like other drivers due to Graph API limitations.
  # X-Zammad-Verify and X-Zammad-Ignore headers are removed from mails sent via Graph API.
  # Thus it's not possible to verify Graph API connection by sending email with such header to yourself.
  def check_configuration(options)
    setup_connection(options)

    _collection, count_all = messages_iterator(false, options)

    Rails.logger.info 'check only mode, fetch no emails'

    {
      result:           'ok',
      content_messages: count_all,
    }
  end

  def verify_transport(_options, _verify_string)
    raise 'Microsoft Graph email channel is never verified. Thus this method is not implemented.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def fetch_single_message(message_id, count, count_all) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
    message_meta = @graph.get_message_basic_details(message_id)

    message_validator = MessageValidator.new(message_meta[:headers], message_meta[:size])

    # ignore fresh verify messages
    if message_validator.fresh_verify_message?
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has a verify message"

      return MessageResult.new(success: false)
    end

    # ignore already imported
    if message_validator.already_imported?(@keep_on_server, @channel)
      begin
        @graph.mark_message_as_read(message_id)
        Rails.logger.info "Ignore message #{count}/#{count_all}, because message message id already imported. Graph API Message ID: #{message_id}."
      rescue MicrosoftGraph::ApiError => e
        Rails.logger.error "Unable to mark email as read #{count}/#{count_all} from Microsoft Graph server (#{@options[:user]}). Graph API Message ID: #{message_id}. #{e.inspect}"
        raise e
      end

      return MessageResult.new(success: false)
    end

    # delete email from server after article was created
    begin
      msg = @graph.get_raw_message(message_id)
    rescue MicrosoftGraph::ApiError => e
      Rails.logger.error "Unable to fetch email #{count}/#{count_all} from Microsoft Graph server (#{@options[:user]}). Graph API Message ID: #{message_id}. #{e.inspect}"
      raise e
    end

    # do not process too big messages, instead download & send postmaster reply
    too_large_info = message_validator.too_large?
    if too_large_info
      if Setting.get('postmaster_send_reject_if_mail_too_large') == true
        info = "  - download message #{count}/#{count_all} - ignore message because it's too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB) - Graph API Message ID: #{message_id}"
        Rails.logger.info info
        after_action = [:notice, "#{info}\n"]
        process_oversized_mail(@channel, msg)
      else
        info = "  - ignore message #{count}/#{count_all} - because message is too large (is:#{too_large_info[0]} MB/max:#{too_large_info[1]} MB) - Graph API Message ID: #{message_id}"
        Rails.logger.info info

        return MessageResult.new(success: false, after_action: [:too_large_ignored, "#{info}\n"])
      end
    else
      process(@channel, msg, false)
    end

    if @keep_on_server
      begin
        @graph.mark_message_as_read(message_id)
      rescue MicrosoftGraph::ApiError => e
        Rails.logger.error "Unable to mark email as read #{count}/#{count_all} from Microsoft Graph server (#{@options[:user]}). Graph API Message ID: #{message_id}. #{e.inspect}"
        raise e
      end
    else
      begin
        @graph.delete_message(message_id)
      rescue MicrosoftGraph::ApiError => e
        Rails.logger.error "Unable to delete #{count}/#{count_all} from Microsoft Graph server (#{@options[:user]}). Graph API Message ID: #{message_id}. #{e.inspect}"
        raise e
      end
    end

    MessageResult.new(success: true, after_action: after_action)
  end

  def messages_iterator(keep_on_server, options)
    if options[:folder_id].present?
      folder_id = options[:folder_id]
      verify_folder!(folder_id, options)
    end

    # Taking first page of messages only effectivelly applies 1000-messages-in-one-go limit
    messages_details = @graph.list_messages(unread_only: keep_on_server, folder_id:, follow_pagination: false)

    ids   = messages_details.fetch(:items).pluck(:id)
    count = messages_details.fetch(:total_count)

    [ids, count]
  rescue MicrosoftGraph::ApiError => e
    Rails.logger.error "Unable to list emails from Microsoft Graph server (#{options[:user]}): #{e.inspect}"
    raise e
  end

  private

  def setup_connection(options)
    access_token = options[:password]
    mailbox      = options[:shared_mailbox].presence || options[:user]

    @graph = MicrosoftGraph.new access_token:, mailbox:
  end

  def verify_folder!(id, options)
    @graph.get_message_folder_details(id)
  rescue MicrosoftGraph::ApiError => e
    raise e if e.error_code != 'ErrorInvalidIdMalformed'

    Rails.logger.error "Unable to fetch email from folder at Microsoft Graph/#{options[:user]} Folder does not exist: #{id}"
    raise "Microsoft Graph email folder does not exist: #{id}"
  end
end
