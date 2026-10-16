# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::QuotedHeader < Service::Base
  requires_current_user!

  Result = Data.define(:from, :to, :cc, :author_name)

  attr_reader :article

  def initialize(article:)
    @article = article
  end

  def execute
    Pundit.authorize current_user, article, :show?

    email_address = quoted_from_email_address

    Result.new(
      from:        from_line(email_address),
      to:          to_line,
      cc:          cc_line,
      author_name: author_name(email_address),
    )
  end

  private

  def from_line(email_address)
    [
      article.author,
      find_user_by_raw_email(article.from)
    ].compact.each do |user|
      result = filtered_user_info(user, sender_email_address: email_address)
      return result if result.present?
    end

    # Nobody resolvable means the header names no known user - keep it, like
    #   the legacy quote header and the recipient lines do.
    article.from
  end

  # Name for the reply citation: follows the sender format for agent authored
  #   articles - names only, never an address. Customers keep their bare name
  #   parts, like the legacy reply citation.
  def author_name(email_address)
    user = article.author
    return if !user

    return user.display_name_from_parts.presence if !user.permissions?('ticket.agent')

    return agent_display_name(user) if !email_address

    email_address.sender_display_name(user)
  end

  def to_line
    %i[to_email_web to_customer to_agent to_default].each do |func|
      result = send(func)
      return result if result.present?
    end

    nil
  end

  def to_email_web
    return if article.type.name != 'email' && article.type.name != 'web'

    filtered_multi_user_info(article.to)
  end

  # Inbound phone articles record the group name as recipient.
  def to_customer
    return if article.sender.name != 'Customer' || article.type.name != 'phone'

    email_address = ::Group.find_by(name: article.to)&.email_address
    return article.to if !email_address

    ::Channel::EmailBuild.recipient_line(email_address.name, email_address.email)
  end

  def to_agent
    return if article.sender.name != 'Agent' || article.type.name != 'phone'

    customer = ::User.find_by(id: article.ticket.customer_id)
    filtered_user_info(customer) || filtered_user_info(find_user_by_raw_email(article.to))
  end

  def to_default
    article.to
  end

  def cc_line
    filtered_multi_user_info(article.cc)
  end

  # Mirrors the per-recipient handling of the legacy quote header: scrub each
  #   recipient on its own, unknown recipients keep their value. Reducing the
  #   line to a single lookup instead would drop the other recipients - or
  #   expose them raw when the first one is unknown.
  def filtered_multi_user_info(input)
    return if input.blank?

    parse_recipients(input)
      .map { |address, raw| filtered_user_info(find_user_by_email(address)) || raw }
      .join(', ')
  end

  # Mailbox list parsing keeps quoted display names with commas intact
  #   ('"Doe, John" <j@example.com>'); lists the parser rejects fall back to
  #   comma splitting with the raw address extraction.
  def parse_recipients(input)
    addresses = Mail::AddressList.new(input).addresses
    return split_recipients(input) if addresses.blank?

    addresses.map { |address| [address.address, address.format] }
  rescue Mail::Field::ParseError
    split_recipients(input)
  end

  def split_recipients(input)
    elements = input
      .split(%r{[,;]})
      .map(&:strip)
      .compact_blank
      .map { |element| [extract_raw_email(element), element] }

    # Without any address there is nothing to scrub - keep the line verbatim.
    return [[nil, input.strip]] if elements.none? { |address, _| address }

    elements
  end

  # Prefer the address the mail was actually sent from (stored at send time) -
  #   the ticket may have been moved or the group address changed since.
  def quoted_from_email_address
    ::EmailAddress.find_by(id: article.preferences['email_address_id']) || article.ticket.group.email_address
  end

  def find_user_by_raw_email(string)
    find_user_by_email(extract_raw_email(string))
  end

  # Do not allow whitespace, quotes or separators inside the address: display
  #   names can contain email addresses themselves - for users without a name
  #   Zammad builds headers like '"user@example.com" <user@example.com>' - and
  #   a match bleeding into those characters would extract garbage, skip the
  #   user lookup and expose the raw header field.
  def extract_raw_email(string)
    string.to_s[%r{<?([^\s"<,;]+@[^>\s",;]+)>?}, 1]
  end

  # User emails are stored in lower case, header addresses may not be.
  def find_user_by_email(email)
    return if email.blank?

    ::User.find_by(email: email.downcase)
  end

  # Pass sender_email_address only for the quoted From line: it pairs agents
  #   with the configured sender format and the group address, mirroring the
  #   original outbound mail. Recipient (To/CC) lines must not use it - the
  #   mail was never received at the group address.
  def filtered_user_info(user, sender_email_address: nil)
    return if !user

    # User 1 creates every inbound mail without being its sender - its
    #   placeholder identity must never be rendered, the header value decides.
    return if user.id == 1

    if !user.permissions?('ticket.agent')
      return ::Channel::EmailBuild.recipient_line(user.fullname, user.email) if user.email

      return user.fullname.presence
    end

    return agent_display_name(user) if !sender_email_address

    ::Channel::EmailBuild.recipient_line(sender_email_address.sender_display_name(user), sender_email_address.email)
  end

  # Agents must not fall back to personal data (email, phone) when only their
  #   name may be shown. The label also prevents the fallthrough to the raw
  #   header field, which would expose the address again. The part ordering
  #   follows user_name_format, like displayNameFromParts() in the legacy
  #   quote header does.
  def agent_display_name(user)
    user.display_name_from_parts.presence || Translation.translate(current_user.locale, __('Agent'))
  end
end
