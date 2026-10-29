# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Channel::EmailParser::ErrorTicket
  TITLE = __('Unprocessable email')
  BODY  = __('This ticket was created because the email could not be processed. The original email and the processing log are attached.')

  attr_reader :channel, :msg, :error

  def initialize(channel:, msg:, error:)
    @channel = channel
    @msg     = msg
    @error   = error
  end

  def create!
    UserInfo.with_user_id(1) do
      Transaction.execute(interface_handle: "#{ApplicationHandleInfo.current}.postmaster") do
        customer = identify_customer
        ticket   = create_ticket(customer)
        article  = create_article(ticket)

        [ticket, article, customer, nil]
      end
    end
  end

  private

  # The mail failed to process once already, so it is only read as far as it goes,
  #   without the content parser or the sanitizer that may have caused the failure.
  def mail
    @mail ||= Mail.new(Mail::Utilities.binary_unsafe_to_crlf(msg.dup.force_encoding('binary')))
  end

  # The decoded value, as regular processing reads it, so that both identify the same sender.
  def header(name)
    field = Array(mail.header[name]).first
    return if field.nil?

    TextEncoding.utf8_encode(decoded_value(field))
  rescue => e
    Rails.logger.error "Unable to read the #{name} header of an unprocessable email: #{e.inspect}"
    nil
  end

  def decoded_value(field)
    field.decoded
  rescue
    field.value
  end

  def identify_customer
    sender = Channel::EmailParser.sender_attributes(sender_headers)
    return User.find(1) if sender[:from_email].blank?

    # A statement failing in here would abort the surrounding transaction, and the fallback below with it.
    ActiveRecord::Base.transaction(requires_new: true) do
      Channel::Filter::BaseIdentifyUser.user_create_without_email(
        login:     sender[:from_email],
        firstname: sender[:from_display_name].presence || sender[:from_email],
        email:     sender[:from_email],
      )
    end
  rescue => e
    Rails.logger.error "Unable to identify the customer of an unprocessable email: #{e.inspect}"
    User.find(1)
  end

  def sender_headers
    Channel::EmailParser::SENDER_FIELDS.index_with { |name| header(name) }.with_indifferent_access
  end

  def create_ticket(customer)
    Ticket.create!(
      group:       Channel::Filter::IdentifyGroup.pick_group(channel, { to: header('To') }),
      customer:    customer,
      title:       translate(TITLE),
      preferences: { channel_id: channel[:id] }.compact,
    )
  end

  def create_article(ticket)
    article = Ticket::Article.create!(
      ticket:       ticket,
      type:         Ticket::Article::Type.lookup(name: 'note'),
      sender:       Ticket::Article::Sender.lookup(name: 'System'),
      from:         header('From'),
      message_id:   header('Message-ID'),
      content_type: 'text/plain',
      body:         translate(BODY),
      internal:     true,
      preferences:  { email_unprocessable: true },
    )

    create_attachment(article, 'unprocessable_email.eml', msg, 'message/rfc822', 'raw')
    create_attachment(article, 'processing_log.txt', processing_log, 'text/plain', 'log')

    article
  end

  def create_attachment(article, filename, data, mime_type, marker)
    Store.create!(
      object:      'Ticket::Article',
      o_id:        article.id,
      data:        data,
      filename:    filename,
      preferences: {
        'Content-Type'        => mime_type,
        'Mime-Type'           => mime_type,
        'email_unprocessable' => marker,
      },
    )
  end

  def processing_log
    <<~LOG
      Failed at: #{Time.zone.now.iso8601}
      Exception: #{error.class}
      Message: #{TextEncoding.utf8_encode(error.message.to_s, fallback: :read_as_sanitized_binary)}

      #{Array(error.backtrace).join("\n")}
    LOG
  end

  def translate(string)
    Translation.translate(Setting.get('locale_default') || 'en-us', string)
  end
end
