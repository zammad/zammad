# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# encoding: utf-8

class Channel::EmailParser
  include Channel::EmailHelper

  PROCESS_TIME_MAX = 180
  EMAIL_REGEX = %r{.+@.+}
  RECIPIENT_FIELDS = %w[to cc delivered-to x-original-to envelope-to].freeze
  SENDER_FIELDS = %w[from reply-to return-path sender].freeze
  EXCESSIVE_LINKS_MSG = __('This message cannot be displayed because it contains over 5,000 links. Download the raw message below and open it via an Email client if you still wish to view it.').freeze
  MESSAGE_STRUCT = Struct.new(:from_display_name, :subject, :msg_size).freeze

=begin

  parser = Channel::EmailParser.new
  mail = parser.parse(msg_as_string, allow_missing_attribute_exceptions: true | false)

  mail = {
    from:              'Some Name <some@example.com>',
    from_email:        'some@example.com',
    from_local:        'some',
    from_domain:       'example.com',
    from_display_name: 'Some Name',
    message_id:        'some_message_id@example.com',
    to:                'Some System <system@example.com>',
    cc:                'Somebody <somebody@example.com>',
    subject:           'some message subject',
    body:              'some message body',
    content_type:      'text/html', # text/plain
    date:              Time.zone.now,
    attachments:       [
      {
        data:        'binary of attachment',
        filename:    'file_name_of_attachment.txt',
        preferences: {
          'content-alternative' => true,
          'Mime-Type'           => 'text/plain',
          'Charset:             => 'iso-8859-1',
        },
      },
    ],

    # ignore email header
    x-zammad-ignore: 'false',

    # customer headers
    x-zammad-customer-login:     '',
    x-zammad-customer-email:     '',
    x-zammad-customer-firstname: '',
    x-zammad-customer-lastname:  '',

    # ticket headers (for new tickets)
    x-zammad-ticket-group:    'some_group',
    x-zammad-ticket-state:    'some_state',
    x-zammad-ticket-priority: 'some_priority',
    x-zammad-ticket-owner:    'some_owner_login',

    # ticket headers (for existing tickets)
    x-zammad-ticket-followup-group:    'some_group',
    x-zammad-ticket-followup-state:    'some_state',
    x-zammad-ticket-followup-priority: 'some_priority',
    x-zammad-ticket-followup-owner:    'some_owner_login',

    # article headers
    x-zammad-article-internal: false,
    x-zammad-article-type:     'agent',
    x-zammad-article-sender:   'customer',

    # all other email headers
    some-header: 'some_value',
  }

=end

  def parse(msg, allow_missing_attribute_exceptions: true)
    msg = msg.dup.force_encoding('binary')
    # mail 2.6 and earlier accepted non-conforming mails that lacked the correct CRLF seperators,
    # mail 2.7 and above require CRLF so we force it on using binary_unsafe_to_crlf
    msg = Mail::Utilities.binary_unsafe_to_crlf(msg)
    mail = Mail.new(msg)

    message_ensure_message_id(msg, mail)

    Channel::EmailParser::Encoding.force_parts_encoding_if_needed(mail)

    headers = Channel::EmailParser::HeadersParser.new(mail).message_header_hash
    body    = Channel::EmailParser::ContentParser.new(mail).message_body_hash

    sender_attributes = self.class.sender_attributes(headers)

    if allow_missing_attribute_exceptions && sender_attributes.blank?
      msg = __('Could not parse any sender attribute from the email. Checked fields:')
      msg += ' '
      msg += SENDER_FIELDS.map { |f| f.split('-').map(&:capitalize).join('-') }.join(', ')

      raise Exceptions::MissingAttribute.new('email', msg)
    end

    message_attributes = [
      { mail_instance: mail },
      headers,
      body,
      sender_attributes,
      { raw: msg },
    ]
    message_attributes.reduce({}.with_indifferent_access, &:merge)
  end

=begin

  parser = Channel::EmailParser.new
  ticket, article, user, mail = parser.process(channel, email_raw_string)

returns

  [ticket, article, user, mail]

do not raise an exception - e. g. if used by scheduler

  parser = Channel::EmailParser.new
  ticket, article, user, mail = parser.process(channel, email_raw_string, false)

returns

  [ticket, article, user, mail] || false

=end

  def process(channel, msg, exception = true)
    process_with_timeout(channel, msg)
  rescue => e
    failed_email = ::FailedEmail.create!(data: msg, parsing_error: e)

    message = <<~MESSAGE.chomp
      Can't process email. Run the following command to get the message for issue report at https://github.com/zammad/zammad/issues:
        zammad run rails r "puts FailedEmail.find(#{failed_email.id}).data"
    MESSAGE

    puts "ERROR: #{message}" # rubocop:disable Rails/Output
    puts "ERROR: #{e.inspect}" # rubocop:disable Rails/Output
    Rails.logger.error message
    Rails.logger.error e

    return false if exception == false

    raise failed_email.parsing_error
  end

  def process_with_timeout(channel, msg)
    Timeout.timeout(PROCESS_TIME_MAX) do
      _process(channel, msg)
    end
  end

  def _process(channel, msg)

    # parse email
    mail = parse(msg)

    Rails.logger.info "Process email with msgid '#{mail[:message_id]}'"

    # run postmaster pre filter
    UserInfo.current_user_id = 1

    # set interface handle
    original_interface_handle = ApplicationHandleInfo.current
    transaction_params = { interface_handle: "#{original_interface_handle}.postmaster", disable: [] }

    filters = {}
    Setting.where(area: 'Postmaster::PreFilter').reorder(:name).each do |setting|
      filters[setting.name] = Setting.get(setting.name).constantize
    end
    filters.each do |key, backend|
      Rails.logger.debug { "run postmaster pre filter #{key}: #{backend}" }
      begin
        backend.run(channel, mail, transaction_params)
      rescue => e
        Rails.logger.error "can't run postmaster pre filter #{key}: #{backend}"
        Rails.logger.error e.inspect
        raise e
      end
    end

    # check ignore header
    if ['true', true].include?(mail[:'x-zammad-ignore'])
      Rails.logger.info "ignored email with msgid '#{mail[:message_id]}' from '#{mail[:from]}' because of x-zammad-ignore header"

      return [{}, nil, nil, mail]
    end

    ticket       = nil
    article      = nil
    session_user = nil

    # https://github.com/zammad/zammad/issues/2401
    mail = prepare_idn_inbound(mail)

    # use transaction
    Transaction.execute(transaction_params) do

      # get sender user
      session_user_id = mail[:'x-zammad-session-user-id']
      if !session_user_id
        raise __('No x-zammad-session-user-id, no sender set!')
      end

      session_user = User.lookup(id: session_user_id)
      if !session_user
        raise "No user found for x-zammad-session-user-id: #{session_user_id}!"
      end

      # set current user
      UserInfo.current_user_id = session_user.id

      # get ticket# based on email headers
      if mail[:'x-zammad-ticket-id']
        ticket = Ticket.find_by(id: mail[:'x-zammad-ticket-id'])
      end
      if mail[:'x-zammad-ticket-number']
        ticket = Ticket.find_by(number: mail[:'x-zammad-ticket-number'])
      end

      # set ticket state to open if not new
      if ticket
        set_attributes_by_x_headers(ticket, 'ticket', mail, 'followup')

        # save changes set by x-zammad-ticket-followup-* headers
        ticket.save! if ticket.has_changes_to_save?

        # set ticket to open again or keep create state
        if !mail[:'x-zammad-ticket-followup-state'] && !mail[:'x-zammad-ticket-followup-state_id']
          new_state = Ticket::State.find_by(default_create: true)
          if ticket.state_id != new_state.id && !mail[:'x-zammad-out-of-office']
            ticket.state = Ticket::State.find_by(default_follow_up: true)
            ticket.save!
          end
        end

        # apply tags to ticket
        if mail[:'x-zammad-ticket-followup-tags'].present?
          tags = mail[:'x-zammad-ticket-followup-tags']
          tags = tags.strip.split(',') if tags.is_a?(String)

          tags.each do |tag|
            ticket.tag_add(tag, sourceable: mail[:'x-zammad-ticket-followup-tags-source'])
          end
        end
      end

      # create new ticket
      if !ticket

        preferences = {}
        preferences[:channel_id] = channel[:id] if channel[:id]

        ticket = Ticket.new(
          title:       mail[:subject].presence || '-',
          preferences: preferences,
        )
        set_attributes_by_x_headers(ticket, 'ticket', mail)

        # create ticket
        ticket.save!

        # apply tags to ticket
        if mail[:'x-zammad-ticket-tags'].present?
          tags = mail[:'x-zammad-ticket-tags']
          tags = tags.strip.split(',') if tags.is_a?(String)

          tags.each do |tag|
            ticket.tag_add(tag, sourceable: mail[:'x-zammad-ticket-tags-source'])
          end
        end
      end

      # set attributes
      article = Ticket::Article.new(
        ticket_id:    ticket.id,
        type_id:      Ticket::Article::Type.find_by(name: 'email').id,
        sender_id:    Ticket::Article::Sender.find_by(name: 'Customer').id,
        content_type: mail[:content_type],
        body:         mail[:body],
        from:         mail[:from],
        reply_to:     mail[:'reply-to'],
        to:           mail[:to],
        cc:           mail[:cc],
        subject:      mail[:subject],
        message_id:   mail[:message_id],
        internal:     false,
      )

      # x-headers lookup
      set_attributes_by_x_headers(article, 'article', mail)

      # Store additional information in preferences, e.g. if remote content got removed.
      article.preferences.merge!(mail[:sanitized_body_info])

      # create article
      article.save!

      # store mail plain
      article.save_as_raw(msg)

      # store attachments
      mail[:attachments]&.each do |attachment|
        filename = attachment[:filename].dup.force_encoding('utf-8')
        if !filename.force_encoding('UTF-8').valid_encoding?
          filename = filename.utf8_encode(fallback: :read_as_sanitized_binary)
        end
        Store.create!(
          object:      'Ticket::Article',
          o_id:        article.id,
          data:        attachment[:data],
          filename:    filename,
          preferences: attachment[:preferences]
        )
      end
    end

    ticket.reload
    article.reload
    session_user.reload

    # run postmaster post filter
    filters = {}
    Setting.where(area: 'Postmaster::PostFilter').reorder(:name).each do |setting|
      filters[setting.name] = Setting.get(setting.name).constantize
    end
    filters.each_value do |backend|
      Rails.logger.debug { "run postmaster post filter #{backend}" }
      begin
        backend.run(channel, mail, ticket, article, session_user)
      rescue => e
        Rails.logger.error "can't run postmaster post filter #{backend}"
        Rails.logger.error e.inspect
      end
    end

    # return new objects
    [ticket, article, session_user, mail]
  end

  def self.mail_to_group(to)
    begin
      to = Mail::AddressList.new(to)&.addresses&.first&.address
    rescue
      Rails.logger.error 'Can not parse :to field for group destination!'
    end
    return if to.blank?

    email = EmailAddress.find_by(email: to.downcase)
    return if email&.channel.blank?

    email.channel&.group
  end

  def self.check_attributes_by_x_headers(header_name, value)
    class_name = nil
    attribute = nil
    # skip check attributes if it is tags
    return true if header_name == 'x-zammad-ticket-tags'

    if header_name =~ %r{^x-zammad-(.+?)-(followup-|)(.*)$}i
      class_name = $1
      attribute = $3
    end
    return true if !class_name

    if class_name.casecmp('article').zero?
      class_name = 'Ticket::Article'
    end
    return true if !attribute

    key_short = attribute[ attribute.length - 3, attribute.length ]
    return true if key_short != '_id'

    class_object = class_name.to_classname.constantize
    return if !class_object

    class_instance = class_object.new

    return false if !class_instance.association_id_validation(attribute, value)

    true
  end

  def self.sender_attributes(from)
    if from.is_a?(ActiveSupport::HashWithIndifferentAccess)
      from = SENDER_FIELDS.filter_map { |f| from[f] }
                          .map(&:to_utf8).compact_blank
                          .partition { |address| address.match?(EMAIL_REGEX) }
                          .flatten.first
    end

    data = {}.with_indifferent_access
    return data if from.blank?

    from = from.gsub('<>', '').strip
    mail_address = begin
      Mail::AddressList.new(from).addresses
                       .select { |a| a.address.present? }
                       .partition { |a| a.address.match?(EMAIL_REGEX) }
                       .flatten.first
    rescue Mail::Field::ParseError => e
      $stdout.puts e
    end

    if mail_address&.address.present?
      data[:from_email]        = mail_address.address
      data[:from_local]        = mail_address.local
      data[:from_domain]       = mail_address.domain
      data[:from_display_name] = mail_address.display_name || mail_address.comments&.first
    elsif from =~ %r{^(.+?)<((.+?)@(.+?))>}
      data[:from_email]        = $2
      data[:from_local]        = $3
      data[:from_domain]       = $4
      data[:from_display_name] = $1
    else
      data[:from_email]        = from
      data[:from_local]        = from
      data[:from_domain]       = from
      data[:from_display_name] = from
    end

    # do extra decoding because we needed to use field.value
    data[:from_display_name] =
      Mail::Field.new('X-From', data[:from_display_name].to_utf8)
                 .to_s
                 .delete('"')
                 .strip
                 .gsub(%r{(^'|'$)}, '')

    data
  end

  def set_attributes_by_x_headers(item_object, header_name, mail, suffix = false)

    # loop all x-zammad-header-* headers
    item_object.attributes.each_key do |key|

      # ignore read only attributes
      next if key == 'updated_by_id'
      next if key == 'created_by_id'

      # check if id exists
      key_short = key[ key.length - 3, key.length ]
      if key_short == '_id'
        key_short = key[ 0, key.length - 3 ]
        header = "x-zammad-#{header_name}-#{key_short}"
        if suffix
          header = "x-zammad-#{header_name}-#{suffix}-#{key_short}"
        end

        # only set value on _id if value/reference lookup exists
        if mail[header.to_sym]

          Rails.logger.info "set_attributes_by_x_headers header #{header} found #{mail[header.to_sym]}"
          item_object.class.reflect_on_all_associations.map do |assoc|

            next if assoc.name.to_s != key_short

            Rails.logger.info "set_attributes_by_x_headers found #{assoc.class_name} lookup for '#{mail[header.to_sym]}'"
            item = assoc.class_name.constantize
            assoc_object = nil
            if item.new.respond_to?(:name)
              assoc_object = item.lookup(name: mail[header.to_sym])
            end
            if !assoc_object && item.new.respond_to?(:login)
              assoc_object = item.lookup(login: mail[header.to_sym])
            end
            if !assoc_object && item.new.respond_to?(:email)
              assoc_object = item.lookup(email: mail[header.to_sym])
            end

            if assoc_object.blank?

              # no assoc exists, remove header
              mail.delete(header.to_sym)
              next
            end

            Rails.logger.info "set_attributes_by_x_headers assign #{item_object.class} #{key}=#{assoc_object.id}"

            item_object[key] = assoc_object.id
            item_object.history_change_source_attribute(mail[:"#{header}-source"], key)
          end
        end
      end

      # check if attribute exists
      header = "x-zammad-#{header_name}-#{key}"
      if suffix
        header = "x-zammad-#{header_name}-#{suffix}-#{key}"
      end
      next if !mail[header.to_sym]

      Rails.logger.info "set_attributes_by_x_headers header #{header} found. Assign #{key}=#{mail[header.to_sym]}"
      item_object[key] = mail[header.to_sym]
      item_object.history_change_source_attribute(mail[:"#{header}-source"], key)
    end
  end

  def self.reprocess_failed_articles
    articles = Ticket::Article.where(body: ::HtmlSanitizer::UNPROCESSABLE_HTML_MSG)
    articles.reorder(id: :desc).as_batches do |article|
      if !article.as_raw&.content
        puts "No raw content for article id #{article.id}! Please verify manually via command: Ticket::Article.find(#{article.id}).as_raw" # rubocop:disable Rails/Output
        next
      end

      puts "Fix article #{article.id}..." # rubocop:disable Rails/Output

      ApplicationHandleInfo.use('email_parser.postmaster') do
        parsed = Channel::EmailParser.new.parse(article.as_raw.content)
        if parsed[:body] == ::HtmlSanitizer::UNPROCESSABLE_HTML_MSG
          puts "ERROR: Failed to reprocess the article, please verify the content of the article and if needed increase the timeout (see: Setting.get('html_sanitizer_processing_timeout'))." # rubocop:disable Rails/Output
          next
        end

        article.update!(body: parsed[:body], content_type: parsed[:content_type])
      end
    end

    puts "#{articles.count} articles are affected." # rubocop:disable Rails/Output
  end

=begin

  process oversized emails by
  - Reply with a postmaster message to inform the sender

=end

  def process_oversized_mail(channel, msg)
    postmaster_response(channel, msg)
  end

  private

  # generate Message ID on the fly if it was missing
  # yes, Mail gem generates one in some cases
  # but it is 100% random so duplicate messages would not be detected
  def message_ensure_message_id(raw, parsed)
    field = parsed.header.fields.find { |elem| elem.name == 'Message-ID' }

    return true if field&.unparsed_value.present?

    parsed.message_id = generate_message_id(raw, parsed.from)
  end

  # Auto reply as the postmaster to oversized emails with:
  # [undeliverable] Message too large
  def postmaster_response(channel, msg)
    begin
      reply_mail = compose_postmaster_reply(msg)
    rescue NotificationFactory::FileNotFoundError => e
      Rails.logger.error "No valid postmaster email_oversized template found. Skipping postmaster reply. #{e.inspect}"
      return
    end

    Rails.logger.info "Send mail too large postmaster message to: #{reply_mail[:to]}"
    reply_mail[:from] = EmailAddress.find_by(channel: channel).email
    channel.deliver(reply_mail)
  rescue => e
    Rails.logger.error "Error during sending of postmaster oversized email auto-reply: #{e.inspect}\n#{e.backtrace}"
  end

  # Compose a "Message too large" reply to the given message
  def compose_postmaster_reply(raw_incoming_mail, locale = nil)
    parsed_incoming_mail = Channel::EmailParser.new.parse(raw_incoming_mail)

    # construct a dummy mail object
    mail = MESSAGE_STRUCT.new
    mail.from_display_name = parsed_incoming_mail[:from_display_name]
    mail.subject = parsed_incoming_mail[:subject]
    mail.msg_size = format('%<MB>.2f', MB: raw_incoming_mail.size.to_f / 1024 / 1024)

    reply = NotificationFactory::Mailer.template(
      template:   'email_oversized',
      locale:     locale,
      format:     'txt',
      objects:    {
        mail: mail,
      },
      raw:        true, # will not add application template
      standalone: true, # default: false - will send header & footer
    )

    reply.merge(
      to:            parsed_incoming_mail[:from_email],
      body:          reply[:body].gsub(%r{\n}, "\r\n"),
      content_type:  'text/plain',
      References:    parsed_incoming_mail[:message_id],
      'In-Reply-To': parsed_incoming_mail[:message_id],
    )
  end

  def guess_email_fqdn(from)
    Mail::Address.new(from).domain.strip
  rescue
    nil
  end

  def generate_message_id(raw_message, from)
    fqdn = guess_email_fqdn(from) || 'zammad_generated'

    "<gen-#{Digest::MD5.hexdigest(raw_message)}@#{fqdn}>"
  end
end
