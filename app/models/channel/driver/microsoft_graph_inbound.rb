# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::MicrosoftGraphInbound < Channel::Driver::BaseEmailInbound

  def self.post_import_action(options)
    options[:post_import_action].presence || (ActiveModel::Type::Boolean.new.cast(options[:keep_on_server]) ? 'mark_read' : 'delete')
  end

  def self.validate_post_import_options!(options)
    action = post_import_action(options)
    raise Exceptions::UnprocessableContent, __('Invalid action after importing messages.') if %w[mark_read delete move].exclude?(action)

    return if action != 'move'

    destination = options[:move_to_folder_id]
    raise Exceptions::UnprocessableContent, __('Please select a destination folder.') if destination.blank?
    raise Exceptions::UnprocessableContent, __('The destination folder must differ from the source folder.') if destination == (options[:folder_id].presence || 'inbox')
  end

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

    Rails.logger.info '  - check only mode, fetch no emails'

    {
      result:           'ok',
      content_messages: count_all,
    }
  end

  def verify_transport(_options, _verify_string)
    raise 'Microsoft Graph email channel is never verified. Thus this method is not implemented.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def fetch_single_message(message_id, count, count_all)
    message_meta = message_details(message_id)
    return MessageResult.new(success: false) if !message_meta

    message_validator = MessageValidator.new(message_meta[:headers], message_meta[:size])

    # ignore fresh verify messages
    if message_validator.fresh_verify_message?
      Rails.logger.info "  - ignore message #{count}/#{count_all} - because message has a verify message"

      return MessageResult.new(success: false)
    end

    return fetch_and_move_message(message_id, message_validator, count, count_all) if @post_import_action == 'move' || message_id == pending_move_id

    # ignore already imported
    if message_validator.already_imported?(@keep_on_server, @channel)
      post_import_message(message_id)
      Rails.logger.info "Ignore message #{count}/#{count_all}, because message message id already imported. Graph API Message ID: #{message_id}."

      return MessageResult.new(success: false)
    end

    msg = fetch_raw_message(message_id, count, count_all)
    result = process_fetched_message(msg, message_id, message_validator, count, count_all)
    return result if !result.success

    post_import_message(message_id)
    result
  end

  def messages_iterator(keep_on_server, options)
    verify_move_folders!(options) if @post_import_action == 'move'

    if options[:folder_id].present?
      folder_id = options[:folder_id]
      verify_folder!(folder_id, options) if @post_import_action != 'move'
    end

    # Taking first page of messages only effectivelly applies 1000-messages-in-one-go limit
    messages_details = @graph.list_messages(unread_only: keep_on_server, folder_id:, follow_pagination: false)

    ids = messages_details.fetch(:items).pluck(:id)
    pending = pending_move_id
    ids.unshift(pending).uniq! if pending
    count = messages_details.fetch(:total_count)

    [ids, count]
  rescue MicrosoftGraph::ApiError => e
    Rails.logger.error "Unable to list emails from Microsoft Graph server (#{options[:user]}): #{e.inspect}"
    raise e
  end

  private

  def process_with_timeout(channel, msg)
    return super if @post_import_action != 'move' && pending_move_id.blank?

    # The parser rescues failures outside this savepoint; partial imports must roll back first.
    Channel.transaction(requires_new: true) { super }
  end

  def message_details(message_id)
    @graph.get_message_basic_details(message_id)
  rescue MicrosoftGraph::ApiError => e
    raise if e.error_code != 'ErrorItemNotFound' || message_id != pending_move_id

    clear_pending_move!
    nil
  end

  def clear_pending_move!
    @channel.preferences.delete(:microsoft_graph_pending_move)
    persist_move_receipt!
  rescue
    @channel.reload
    raise
  end

  def persist_move_receipt!
    # Receipt writes must not run email-address cleanup for every imported message.
    saved = @channel.update_column(:preferences, @channel.preferences) # rubocop:disable Rails/SkipsModelValidations
    raise ActiveRecord::RecordNotSaved if !saved
  end

  def pending_move_id
    return if !@channel

    pending = @channel.preferences[:microsoft_graph_pending_move]
    return if pending.blank?

    context_keys = %i[mailbox cloud client_tenant]
    return if pending.slice(*context_keys) != move_receipt(nil, '').slice(*context_keys)

    pending[:message_id]
  end

  def fetch_raw_message(message_id, count, count_all)
    @graph.get_raw_message(message_id)
  rescue MicrosoftGraph::ApiError => e
    Rails.logger.error "Unable to fetch email #{count}/#{count_all} from Microsoft Graph server (#{@options[:user]}). Graph API Message ID: #{message_id}. #{e.inspect}"
    raise
  end

  def process_fetched_message(msg, message_id, message_validator, count, count_all)
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

    MessageResult.new(success: true, after_action: after_action)
  end

  def fetch_and_move_message(message_id, message_validator, count, count_all)
    msg = fetch_raw_message(message_id, count, count_all)
    receipt = move_receipt(message_id, msg)
    result = Channel.transaction do
      if @channel.preferences[:microsoft_graph_pending_move] == receipt
        MessageResult.new(success: false)
      else
        processed = process_fetched_message(msg, message_id, message_validator, count, count_all)
        if processed.success
          @channel.preferences[:microsoft_graph_pending_move] = receipt
          persist_move_receipt!
        end
        processed
      end
    end
    return result if result.after_action&.first == :too_large_ignored

    post_import_message(message_id)
    clear_pending_move!
    result
  rescue
    @channel.reload
    raise
  end

  def move_receipt(message_id, msg)
    {
      message_id:    message_id,
      sha256:        Digest::SHA256.hexdigest(msg),
      mailbox:       (@options[:shared_mailbox].presence || @options[:user]).downcase,
      cloud:         @options[:cloud].presence || 'global',
      client_tenant: @channel.options.dig(:auth, :client_tenant).presence,
    }.with_indifferent_access
  end

  def verify_move_folders!(options)
    source = verify_folder!(options[:folder_id].presence || 'inbox', options)
    destination = verify_folder!(options[:move_to_folder_id], options)
    return if source[:id] != destination[:id]

    raise Exceptions::UnprocessableContent, __('The destination folder must differ from the source folder.')
  end

  def post_import_message(message_id)
    case @post_import_action
    when 'move'
      @graph.move_message(message_id, @options[:move_to_folder_id])
    when 'mark_read'
      @graph.mark_message_as_read(message_id)
    else
      @graph.delete_message(message_id)
    end
  rescue MicrosoftGraph::ApiError => e
    Rails.logger.error "Unable to complete #{@post_import_action} for Microsoft Graph message #{message_id} (#{@options[:user]}). #{e.inspect}"
    raise
  end

  def setup_connection(options)
    self.class.validate_post_import_options!(options)
    @post_import_action = self.class.post_import_action(options)
    @keep_on_server = @post_import_action == 'mark_read'

    access_token = options[:password]
    mailbox      = options[:shared_mailbox].presence || options[:user]

    setup_connection_server_log(options)

    @graph = MicrosoftGraph.new access_token:, mailbox:
  end

  def setup_connection_server_log(options)
    mailbox = options[:shared_mailbox].presence || options[:user]
    config  = [
      *("folder_id=#{options[:folder_id]}" if options[:folder_id].present?),
      "keep_on_server=#{options[:keep_on_server]}",
    ]

    Rails.logger.info "fetching Microsoft Graph (#{mailbox} #{config.join(',')})"
  end

  def verify_folder!(id, options)
    @graph.get_message_folder_details(id)
  rescue MicrosoftGraph::ApiError => e
    raise e if %w[ErrorInvalidIdMalformed ErrorItemNotFound].exclude?(e.error_code)

    Rails.logger.error "Unable to fetch email from folder at Microsoft Graph/#{options[:user]} Folder does not exist: #{id}"
    raise "Microsoft Graph email folder does not exist: #{id}. #{e.message}"
  end
end
