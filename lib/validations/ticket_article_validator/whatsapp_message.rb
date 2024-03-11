# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Validations::TicketArticleValidator
  class WhatsappMessage < Backend
    MATCHING_TYPES = ['whatsapp message'].freeze

    CONTENT_TYPE_OPTIONS = [
      { size: 16 * 1024 * 1024,  identifier: :audio,    label: __('Audio file'), no_caption: true },
      { size: 5 * 1024 * 1024,   identifier: :image,    label: __('Image file') },
      { size: 16 * 1024 * 1024,  identifier: :video,    label: __('Video file') },
      { size: 500 * 1024,        identifier: :sticker,  label: __('Sticker file'), no_caption: true },
      { size: 100 * 1024 * 1024, identifier: :document, label: __('Document file') },
    ].freeze

    def validate_attachments_limit
      return if !all_attachments.many?

      @record.errors.add :base, format(__('Only %s attachment allowed'), 1)
    end

    def validate_attachment_content_type
      return if !attachment
      return if attachment_options

      message = format(__('File format is not allowed: %s'), attachment.preferences['Content-Type'] || attachment.preferences['Mime-Type'])

      @record.errors.add :base, message
    end

    def validate_attachments_size
      return if !attachment_options

      attachment_size = attachment.size.to_i

      return if attachment_size <= attachment_options[:size]

      size    = ActiveSupport::NumberHelper.number_to_human_size attachment_options[:size]
      message = format(__('File is too big. %s has to be %s or smaller.'), attachment_options[:label], size)

      @record.errors.add :base, message
    end

    def validate_body
      return if attachment
      return if @record.body.present?

      @record.errors.add :base, __('Text or attachment is required')
    end

    def validate_body_no_caption
      return if !attachment_options&.dig(:no_caption)
      return if @record.body.blank?

      message = "#{attachment_options[:label]} is sent without text caption"

      @record.errors.add :base, message
    end

    def validate_ticket_state
      return if Ticket::State.where(name: %w[closed merged removed]).pluck(:id).exclude?(@record.ticket.state_id)

      @record.errors.add :base, __('Reply allowed only for open tickets')
    end

    private

    def attachment
      return @attachment if defined?(@attachment)

      @attachment = all_attachments.first
    end

    def attachment_options
      return @attachment_options if defined?(@attachment_options)
      return if !attachment

      attachment_type = attachment.preferences['Content-Type'] || attachment.preferences['Mime-Type']

      @attachment_options = CONTENT_TYPE_OPTIONS.find do |elem|
        Whatsapp::Outgoing::Message::Media::SUPPORTED_MEDIA_TYPES[elem[:identifier]]
          .include? attachment_type
      end
    end

    def all_attachments
      @all_attachments ||= @record.attachments + (@record.instance_variable_get(:@attachments_buffer) || [])
    end

    def validator_applies?
      sender = Ticket::Article::Sender.lookup id: @record.sender_id

      sender.name == 'Agent'
    end
  end
end
