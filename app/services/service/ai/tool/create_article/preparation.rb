# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::CreateArticle::Preparation < Service::Base
  class InvalidArticle < StandardError; end

  RECORD_TYPES = %w[note phone web chat fax].freeze
  # The formats a message is given in, as the REST API takes an article.
  CONTENT_TYPES = %w[text/plain text/html].freeze
  # Where the editor puts the signature in a text it saves, such as a shared draft, before quoted text.
  SIGNATURE_PLACEHOLDER = %r{<div[^>]*\sdata-signature-placeholder[^>]*>\s*</div>}i

  attr_reader :ticket, :user, :arguments, :data, :context

  # The types the tool offers: what Zammad records, what a group sends and what a channel delivers.
  def self.article_types
    [*RECORD_TYPES, 'email', *Channel.article_types]
  end

  def initialize(ticket:, user:, arguments:)
    @ticket = ticket
    @user = user
    @arguments = arguments.with_indifferent_access
    @data = {}
    @context = {}
  end

  def execute
    validate_input
    prepare_common
    if type == 'email'
      prepare_email
    elsif channel_class
      prepare_channel
    elsif RECORD_TYPES.exclude?(type)
      invalid("Zammad has no available outbound delivery for #{type}. Use a supported channel or record a note.")
    end

    # The validators of a change, such as time accounting, ask nothing of a ticket being created.
    Service::Ticket::Update::Validator.execute(current_user: user, ticket:, ticket_data: {}, article_data: data, skip_validators:) if ticket.persisted?
    { article_data: data, confirmation:, outbound: outbound? }
  end

  private

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString

  def type
    arguments[:type]
  end

  def outbound?
    type == 'email' || channel_class.present?
  end

  def channel_class
    Channel.for_type(type)
  end

  def confirmation
    {
      required: outbound? || !data[:internal],
      preview:  confirmation_preview,
      snapshot: {
        ticket:          ticket.slice(:id, :number, :group_id, :customer_id, :state_id),
        last_article_id: ticket.articles.maximum(:id),
        article_data:    data,
        context:,
      },
    }
  end

  def confirmation_preview
    article_data = data.merge(context.slice(:subject))
    [
      "Create #{type} on ticket #{ticket.number}?",
      "Visibility: #{data[:internal] ? 'internal' : 'public'}. An outbound message is sent even when marked internal.",
      *article_data.slice(:from, :to, :cc, :subject, :in_reply_to).filter_map { |key, value| "#{key}: #{Array(value).join(', ')}" if value.present? },
      *("Time accounted: #{data[:time_unit]}" if data[:time_unit]),
      "Content type: #{data[:content_type]}",
      readable_body,
      'Confirm only if these recipients and this complete message match your request.',
    ].join("\n\n")
  end

  def validate_input
    validate_text
    invalid('This article type is unavailable.') if !Ticket::Article::Type.exists?(name: type)
    invalid('Articles cannot be sent while import mode is enabled.') if Setting.get('import_mode')
    invalid('Only email accepts cc or subject.') if type != 'email' && (arguments[:cc].present? || arguments[:subject].present?)
    invalid('This channel takes its destination from the ticket; omit to.') if %w[email sms].exclude?(type) && arguments[:to].present?
    validate_signature_option
    validate_time_unit
  end

  def validate_text
    invalid('text is empty. Give the message.') if arguments[:text].blank?
    invalid('The message is too long (maximum 100000 characters).') if arguments[:text].length > 100_000
    invalid("#{channel_class.label} takes plain text. Use content_type text/plain.") if html? && channel_class
  end

  def validate_time_unit
    return if arguments[:time_unit].nil?

    invalid('Give time_unit or skip_time_accounting, not both.') if arguments[:skip_time_accounting]
    # Any time is taken, as the REST API and the interface take it: 0, and a negative one that corrects an earlier one.
    invalid('Time accounting is switched off in Zammad; omit time_unit.') if !Setting.get('time_accounting')
  end

  def validate_signature_option
    return if !arguments.key?(:include_signature)

    invalid('Only email accepts include_signature.') if type != 'email'
    invalid("argument 'include_signature' must be of type boolean") if [true, false].exclude?(arguments[:include_signature])
  end

  # The user skipped the time, as the time accounting of the interface lets them.
  def skip_validators
    [Service::Ticket::Update::Validator::TimeAccounting] if arguments[:skip_time_accounting] == true
  end

  def prepare_common
    data.merge!(
      type:,
      sender: 'Agent',
      internal: arguments[:internal] || false,
      body: html? ? html_body : arguments[:text],
      content_type: html? ? 'text/html' : 'text/plain',
    )
    data[:time_unit] = arguments[:time_unit] if arguments[:time_unit]
    prepare_reply if arguments[:reply_to_article_id]
  end

  def prepare_reply
    article = ticket.articles.find_by(id: arguments[:reply_to_article_id])
    invalid('The reply article was not found on this ticket.') if !article
    invalid('The selected article belongs to another channel.') if !compatible_reply_type?(article.type.name)
    data[:in_reply_to] = article.message_id if article.message_id.present?
    context[:reply_article] = article.id
  end

  def html?
    arguments[:content_type] == 'text/html'
  end

  # Sanitized here already, so the user confirms the markup Zammad keeps.
  def html_body
    html? ? HtmlSanitizer.strict(arguments[:text]) : arguments[:text].text2html
  end

  # What the message reads like, with the address of each link.
  def readable_body
    data[:content_type] == 'text/html' ? data[:body].html2text : data[:body]
  end

  def compatible_reply_type?(source_type)
    return true if type == 'email'
    return channel_class.replies_to?(source_type) if channel_class

    source_type == type
  end

  def prepare_email
    prepare_email_sender
    prepare_email_recipients
    prepare_email_subject
    data[:body] = html_body
    data[:content_type] = 'text/html'
    append_signature if arguments.fetch(:include_signature, true)
  end

  def prepare_email_sender
    email_address = ticket.group.email_address
    invalid('The ticket group has no active email sender. Configure it in Zammad first.') if !email_address&.active?
    channel = email_address.channel
    invalid('The email sender has no active outbound channel.') if !channel&.active? || channel.options&.dig('outbound', 'adapter').blank?
    context[:channel] = [channel.id, channel.options.dig('outbound', 'adapter')]
    data[:from] = ::Channel::EmailBuild.recipient_line(email_address.sender_display_name(user), email_address.email)
  end

  def prepare_email_recipients
    data[:to] = email_recipients(:to)
    invalid('Email requires explicit to recipients. Read the ticket customer or selected message first.') if data[:to].empty?
    data[:cc] = email_recipients(:cc) - data[:to]
  end

  def prepare_email_subject
    data[:subject] = ticket.subject_clean(arguments[:subject].presence || ticket.title)
    invalid('The subject must be one line.') if data[:subject].match?(%r{[\r\n]})
    # A new ticket's first email is no reply, and its number comes with the save.
    return context[:subject] = data[:subject] if ticket.new_record?

    data[:subtype] = 'reply'
    context[:subject] = ticket.subject_build(data[:subject], 'reply')
  end

  def email_recipients(field)
    Array(arguments[field]).flat_map do |value|
      invalid("#{field} contains an invalid email address.") if value.blank? || value.match?(%r{[\r\n]})
      addresses = Mail::AddressList.new(value).addresses
      invalid("#{field} contains an invalid email address.") if addresses.empty?
      addresses.map do |address|
        invalid("#{field} contains an invalid email address.") if !EmailAddressValidation.new(address.address).valid?
        address.address.downcase
      end
    end.uniq
  rescue Mail::Field::ParseError
    invalid("#{field} contains an invalid email address.")
  end

  def append_signature
    signature = ticket.group.signature
    return if !signature&.active?

    rendered = NotificationFactory::Renderer.new(
      objects: { user:, ticket: }, template: signature.body_with_urls, escape: false
    ).render(debug_errors: false)
    return if rendered.blank?

    data[:body] = data[:body].match?(SIGNATURE_PLACEHOLDER) ? data[:body].sub(SIGNATURE_PLACEHOLDER) { rendered } : "#{data[:body]}<br><br>#{rendered}"
  end

  def prepare_channel
    channel = active_channel
    invalid('The ticket channel is not configured.') if !channel.options.is_a?(Hash)
    context[:channel] = [channel.id, channel.area, channel.options['adapter']]
    context[:destination] = ticket.preferences.slice('channel_id', 'telegram', 'whatsapp', 'channel_fb_object_id')
    channel_class.check(ticket:, arguments:)
    channel_class.new(ticket:, channel:, arguments:, data:).prepare
  end

  # The ticket's channel of the type, active, which a draft needs as well.
  def active_channel
    channel = channel_class.of(ticket)
    invalid('The ticket has no active matching channel.') if !channel&.active? || channel.area != channel_class.area

    channel
  end

  def invalid(message)
    raise InvalidArticle, message
  end
  # rubocop:enable Zammad/DetectTranslatableString
end
