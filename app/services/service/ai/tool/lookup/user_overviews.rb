# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The overviews a user works from, as the overview list of the desktop view shows them — the overview scope decides by
#   the user's roles and restrictions, the user's own order sorts —, and one of them found by its ID or by its name.
class Service::AI::Tool::Lookup::UserOverviews
  # A name that fits no overview of the user, or several: the message lists the user's overviews, so that the caller
  #   needs no list first.
  class Invalid < StandardError
    attr_reader :code

    def initialize(code, message)
      super(message)
      @code = code
    end
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def all
    @all ||= Service::User::Overview::List.with_current_user(user).execute(ignore_user_conditions: false).to_a
  end

  # @return [Array<Service::AI::Tool::Output::Part>] each overview as a row, with the count of its tickets
  def rows
    @rows ||= all.map { |overview| row(overview) }
  end

  def row(overview)
    Service::AI::Tool::Output::Overview.row(overview, user:, ticket_count: ticket_count(overview))
  end

  # @param order [Hash] order_by and order_direction instead of the overview's
  def tickets(overview, **order)
    Service::User::Overview::Tickets.with_current_user(user).execute(overview:, **order)
  end

  def ticket_count(overview)
    Service::User::Overview::TicketCount.with_current_user(user).execute(overview:)
  end

  # The user's overviews as lines of text, for a message that has to name them.
  def listed
    return 'The user has no overview.' if rows.empty? # rubocop:disable Zammad/DetectTranslatableString

    "The user's overviews:\n#{rows.map(&:text).join("\n")}"
  end

  # An overview the user may not use reads as a missing one.
  #
  # @param name [String, nil] as the user sees it or as it is stored, without regard to case: exactly first, then by a
  #   part that fits one overview only
  # @raise [ActiveRecord::RecordNotFound, Invalid]
  def find(id: nil, name: nil)
    return all.find { |overview| overview.id == id } || raise(ActiveRecord::RecordNotFound) if id

    by_name(name)
  end

  private

  def by_name(name)
    wanted = normalized(name)
    exact  = all.select { |overview| names(overview).include?(wanted) }
    return exact.first if exact.one?

    found = exact.presence || all.select { |overview| names(overview).any? { |known| known.include?(wanted) } }
    return found.first if found.one?

    raise invalid(name, found)
  end

  def names(overview)
    [overview.name, Service::AI::Tool::Output::Overview.name_for(overview, user)].map { |known| normalized(known) }.uniq
  end

  def normalized(value)
    value.to_s.downcase.squish
  end

  def invalid(name, found)
    quoted = AI::PromptText.xml_text(name.to_s.squish)
    return Invalid.new('invalid_value', "overview \"#{quoted}\" matches no overview of the user. #{listed}") if found.empty?

    # Names are not unique: the ID tells two of one name apart.
    candidates = found.map { |overview| AI::PromptText.xml_text("#{Service::AI::Tool::Output::Overview.name_for(overview, user)} (ID #{overview.id})") }
    Invalid.new('ambiguous', "overview \"#{quoted}\" matches #{found.size} overviews: #{candidates.join(', ')}. Use the ID or the full name. #{listed}")
  end
end
