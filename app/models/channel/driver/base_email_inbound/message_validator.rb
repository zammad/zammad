# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Channel::Driver::BaseEmailInbound
  class MessageValidator
    attr_reader :headers, :size

    # @param headers [Hash] in key-value format
    # @param size [Integer] in bytes
    def initialize(headers, size = nil)
      @headers = headers
      @size    = size
    end

    # Checks if email is not too big for processing
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def too_large?
      max_message_size = Setting.get('postmaster_max_size').to_f
      real_message_size = size.to_f / 1024 / 1024
      if real_message_size > max_message_size
        return [real_message_size, max_message_size]
      end

      false
    end

    # Checks if a message with the given headers is a Zammad verify message
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def verify_message?
      headers['X-Zammad-Verify'] == 'true'
    end

    # Checks if a message with the given headers marked to be ignored by Zammad
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def ignore?
      headers['X-Zammad-Ignore'] == 'true'
    end

    # Checks if a message is a new Zammad verify message
    #
    # Returns false only if a verify message is less than 30 minutes old
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def fresh_verify_message?
      return false if !verify_message?
      return false if headers['X-Zammad-Verify-Time'].blank?

      begin
        verify_time = Time.zone.parse(headers['X-Zammad-Verify-Time'])
      rescue => e
        Rails.logger.error e
        return false
      end

      verify_time > 30.minutes.ago
    end

    # Checks if a message is already imported in a given channel
    # This check is skipped for channels which do not keep messages on the server
    #
    # This method is used by IMAP and MicrosoftGraphInbound only
    # It may be possible to reuse them with POP3 too, but it needs further refactoring
    def already_imported?(keep_on_server, channel)
      return false if !keep_on_server

      return false if !headers

      local_message_id = headers['Message-ID']
      return false if local_message_id.blank?

      local_message_id_md5 = Digest::MD5.hexdigest(local_message_id)
      article = Ticket::Article.where(message_id_md5: local_message_id_md5).reorder('created_at DESC, id DESC').limit(1).first
      return false if !article

      # verify if message is already imported via same channel, if not, import it again
      ticket = article.ticket
      return false if ticket&.preferences && ticket.preferences[:channel_id].present? && channel.present? && ticket.preferences[:channel_id] != channel[:id]

      true
    end
  end
end
