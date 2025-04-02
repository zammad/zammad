# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::BaseEmailInbound < Channel::EmailParser
  ACTIVE_CHECK_INTERVAL = 20

  MessageResult = Struct.new(:success, :after_action, keyword_init: true)

  def fetchable?(_channel)
    true
  end

  def self.streamable?
    false
  end

  # Checks if the given channel was modified since it it was loaded
  # This check is used in email fetching loop
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

  # Fetches emails
  #
  # @param options [Hash]. See subclass for options
  # @param channel [Channel]
  #
  # @return [Hash]
  #
  #  {
  #    result: 'ok',
  #    fetched: 123,
  #    notice: 'e. g. message about to big emails in mailbox',
  #  }
  def fetch(options, channel)
    @channel        = channel
    @options        = options
    @keep_on_server = ActiveModel::Type::Boolean.new.cast(options[:keep_on_server])

    setup_connection(options)

    collection, count_all = messages_iterator(@keep_on_server, options)
    count_fetched         = 0
    too_large_messages    = []
    result                = 'ok'
    notice                = ''

    collection.each.with_index(1) do |message_id, count|
      break if stop_fetching?(count)

      Rails.logger.info " - message #{count}/#{count_all}"

      message_result = fetch_single_message(message_id, count, count_all)

      count_fetched += 1 if message_result.success

      case message_result.after_action
      in [:too_large_ignored, message]
        notice += message
        too_large_messages << message
      in [:notice, message]
        notice += message
      in [:result_error, message]
        result = 'error'
        notice += message
      else
      end
    end

    fetch_wrap_up

    if count_all.zero?
      Rails.logger.info ' - no message'
    end

    # Error is raised if one of the messages was too large AND postmaster_send_reject_if_mail_too_large is turned off.
    # This effectivelly marks channels as stuck and gets highlighted for the admin.
    # New emails are still processed! But large email is not touched, so error keeps being re-raised on every fetch.
    if too_large_messages.present?
      raise too_large_messages.join("\n")
    end

    {
      result:  result,
      fetched: count_fetched,
      notice:  notice,
    }
  end

  def stop_fetching?(count)
    (count % ACTIVE_CHECK_INTERVAL).zero? && channel_has_changed?(@channel)
  end

  def fetch_wrap_up; end

  # Checks if mailbox has anything besides Zammad verification emails.
  # If any real messages exists, return the real count including messages to be ignored when importing.
  # If only verification messages found, return 0.
  #
  # @param options [Hash] driver-specific server setup. See #fetch in the corresponding driver.
  #
  # @return [Hash]
  #
  # {
  #   result: 'ok'
  #   content_messages: 123 # or 0 if there're none
  # }
  def check_configuration(options)
    setup_connection(options, check: true)

    Rails.logger.info 'check only mode, fetch no emails'

    collection, count_all = messages_iterator(false, options)

    has_content_messages = collection
      .any? do |message_id|
        validator = check_single_message(message_id)

        next if !validator

        !validator.verify_message? && !validator.ignore?
      end

    disconnect

    {
      result:           'ok',
      content_messages: has_content_messages ? count_all : 0,
    }
  end

  # Checks if probing email has arrived
  #
  # This method is used for custom IMAP only.
  # It is not used in conjunction with Micrsofot365 or Gogle OAuth channels.
  #
  # @param options [Hash] driver-specific server setup. See #fetch in the corresponding driver.
  # @param verify_string [String] to check with
  #
  # @return [Hash]
  #
  # {
  #   result: 'ok' # or 'verify not ok' in case of failure
  # }
  def verify_transport(options, verify_string)
    setup_connection(options)

    collection, _count_all = messages_iterator(false, options, reverse: true)

    Rails.logger.info "verify mode, fetch no emails #{verify_string}"

    verify_regexp = %r{#{verify_string}}

    # check for verify message
    verify_message_id = collection.find do |message_id|
      verify_single_message(message_id, verify_regexp)
    end

    result = if verify_message_id
               Rails.logger.info " - verify email #{verify_string} found"
               verify_message_cleanup(verify_message_id)

               'ok'
             else
               'verify not ok'
             end

    disconnect

    { result:, }
  end
end
