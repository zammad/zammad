# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds the ticket a caller names by its ID, a link to it or its number — the most exact one that can be used.
class Service::AI::Tool::Locator::Ticket < Service::AI::Tool::Locator
  locates ::Ticket

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  PARAMETERS = {
    'ticket_number' => { type: :string, description: 'The ticket number as shown in Zammad, e.g. "31042" or "Ticket#31042".' },
    'ticket_id'     => { type: :integer, description: 'The internal ID of the ticket, e.g. 8812.' },
    'ticket_url'    => { type: :string, description: 'A link to the ticket in Zammad.' },
  }.freeze

  NO_NAME             = 'Name the ticket by its ticket_number, ticket_id or ticket_url.'.freeze
  NO_LINK             = 'ticket_url is no link to a ticket of this Zammad. Pass the ticket_number or ticket_id instead.'.freeze
  NOT_IN_CONVERSATION = 'Only the ticket of this conversation, a ticket the agent named in their own messages and a ' \
                        'ticket a tool listed here can be read. Ask the agent before you read another one.'.freeze
  READ_ONLY           = 'You may read this ticket, but not change it: your access to its group is read only. Nothing was ' \
                        'changed. Tell the user; an agent who may change tickets of the group can do it.'.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # How the read tools load a ticket, against which a write's refusal is told apart.
  READ_ACCESS = :agent_read_access?

  # The current interface's paths, which the desktop view and the mobile view take as well, after the link's "#".
  FRAGMENT = %r{\A/?ticket/zoom/(?:number/(?<number>[^/?#]+)|(?<id>\d+))(?:[/?]|\z)}

  # The desktop view's and the mobile view's own paths.
  PATH = %r{\A/(?:desktop|mobile)/(?:tickets|ticket(?:/zoom)?)/(?<id>\d+)(?:/|\z)}

  # How an agent names a ticket in a message: by a link, or by its number; by its ID as every object.
  LINK_IN_TEXT   = %r{https?://[^[:space:]<>"']+}i
  NUMBER_IN_TEXT = %r{(?<!\d)\d+(?!\d)}

  # A sentence's own punctuation after a link.
  TRAILING_PUNCTUATION = %r{[.,;:!?)\]>]+\z}

  Reference = Data.define(:id, :number)

  class << self
    def argument_errors(arguments)
      return [] if !arguments['ticket_id'].nil? || arguments['ticket_url'].nil? || link(arguments['ticket_url'])
      return [] if !arguments['ticket_number'].nil?

      [NO_LINK]
    end

    # @param url [String] a link as a person pasted it, or its part after the host
    # @return [Reference, nil] the ticket a link to this Zammad names
    # Without a host, a link is this Zammad's only as a path or a fragment: another host's without a scheme parses as a
    #   path.
    def link(url)
      url = url.to_s.strip
      uri = URI.parse(url)
      return if uri.scheme.present? && %w[http https].exclude?(uri.scheme.downcase)
      return if uri.host.present? ? !own_address?(uri) : !url.start_with?('/', '#')

      match = FRAGMENT.match(uri.fragment.to_s) || PATH.match(uri.path.to_s)
      return if match.nil?

      captures = match.named_captures
      Reference.new(id: captures['id']&.to_i, number: captures['number'])
    rescue URI::InvalidURIError
      nil
    end

    # @return [Array<Reference>] every ticket a text may name: its links, the IDs it gives and the numbers it holds
    def references_in(text)
      text  = text.to_s
      links = text.scan(LINK_IN_TEXT).filter_map { |url| link(url.sub(TRAILING_PUNCTUATION, '')) }
      ids   = text.scan(self::ID_IN_TEXT).flatten.map { |id| Reference.new(id: id.to_i, number: nil) }

      links + ids + text.scan(NUMBER_IN_TEXT).map { |number| Reference.new(id: nil, number:) }
    end

    # The number as Zammad stores it, from one as people write it: with a leading "#", or with the ticket hook as a
    #   mail subject carries it.
    def normalized_number(number)
      text = number.to_s.strip
      hook = Regexp.escape("#{Setting.get('ticket_hook')}#{Setting.get('ticket_hook_divider')}")

      (text[%r{#{hook}[[:space:]]*(\d+)}i, 1] || text.delete_prefix('#').strip).presence
    end

    private

    # A link to another Zammad would name a ticket with the same ID here.
    def own_address?(uri)
      [Setting.get('fqdn'), Setting.get('alternative_fqdn')].compact_blank.any? do |address|
        host, port = address.downcase.split(':', 2)

        host == uri.host.downcase && (port.nil? || port.to_i == uri.port)
      end
    end
  end

  # @return [Reference, nil] what the caller named, the most exact one that can be used
  def reference
    return Reference.new(id: arguments['ticket_id'], number: nil) if !arguments['ticket_id'].nil?

    link = self.class.link(arguments['ticket_url']) if !arguments['ticket_url'].nil?
    return link if link

    number = self.class.normalized_number(arguments['ticket_number'])
    Reference.new(id: nil, number:) if number
  end

  # @return [Integer, nil] the ID of the named ticket, nil when there is none
  def record_id
    named = reference
    return if named.nil?

    named.id || id_by_number(named.number)
  end

  # Whether the named ticket is one the conversation may read: one of the given IDs, or one the agent named, by its
  #   number, its ID or a link. Named in the same form, it is decided on what was named alone, whether the ticket exists
  #   or not; across the forms — the agent wrote a number, the call gives an ID — only for a ticket the user may read
  #   as an agent. So the answer tells nothing about tickets the user may not see.
  #
  # @param ids [Array<Integer>] the tickets the conversation may read anyway
  # @param texts [Array<String>] what the agent wrote in the conversation
  # @param user [User] as whom the conversation reads
  def named_by?(ids:, texts:, user:)
    named = reference
    return false if named.nil?

    written = texts.flat_map { |text| self.class.references_in(text) }
    ids += written.filter_map(&:id)
    numbers = written.filter_map { |item| self.class.normalized_number(item.number) }
    return true if named.id ? ids.include?(named.id) : numbers.include?(named.number)

    named_in_other_form(named, ids:, numbers:).any? { |ticket| TicketPolicy.new(user, ticket).agent_read_access? }
  end

  private

  def id_by_number(number)
    ::Ticket.where(number:).pick(:id)
  end

  # The named ticket where the agent wrote it in the other form: its number for a named ID, its ID for a named number.
  def named_in_other_form(named, ids:, numbers:)
    named.id ? ::Ticket.where(id: named.id, number: numbers) : ::Ticket.where(number: named.number, id: ids)
  end
end
