# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Phone searches use caller-log normalization first so differently formatted numbers identify the same person.
class Service::AI::Tool::SearchUsers < Service::AI::Tool
  include Service::AI::Tool::Concerns::RecordSearch
  include Service::AI::Tool::Concerns::Sorting

  CALL_FIELDS = Service::AI::Tool::GetUser::CALL_FIELDS

  # Digits and the signs a phone number is written with, at least as many digits as Cti::CallerId extracts.
  PHONE        = %r{\A\+?[\d\s\-()/.]+\z}
  PHONE_DIGITS = 6

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  ROW_SCHEMA = {
    type:       'object',
    properties: Service::AI::Tool::Output::User::SCHEMA[:properties].merge(
      phone:        { type: 'string' },
      mobile:       { type: 'string' },
      organization: Service::AI::Tool::Output::Organization::SCHEMA,
      vip:          { type: 'boolean' },
      active:       { const: false, description: 'Only where the user is inactive.' },
    ),
    required:   %w[type id name],
  }.freeze

  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      query:       { type: 'string', description: 'The words searched for.' },
      users:       { type: 'array', items: ROW_SCHEMA },
      has_more:    { type: 'boolean' },
      next_cursor: { type: 'string', description: 'Pass it as cursor, with the same query, for the next users.' },
    },
    required:   %w[query users has_more],
  }.freeze

  description 'Find users of Zammad — customers and agents, the inactive ones included — by words of their name, an ' \
              'email, a login or a phone number, as Zammad\'s search finds them. Each row names the user\'s ID, ' \
              'email, phone, mobile and organization, so that two people of the same name can be told apart; the ' \
              'other tools take the ID or the email, and get_user reads a user in detail. Pass next_cursor as ' \
              'cursor, with the same query, for the next users.'
  title 'Search users'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents
  searches

  parameter :query, type: :string, required: true, description: 'Words of a name, an email, a login or a phone number, e.g. "Huber" or "+49 30 123456".'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT, description: 'How many users to list.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next users.'
  sortable %w[lastname created_at updated_at], default: 'the active users first, the newest created first'
  # rubocop:enable Zammad/DetectTranslatableString

  private

  def model
    ::User
  end

  def result_key
    :users
  end

  def record_noun
    'user'
  end

  def query_hint
    'Pass a name, an email, a login or a phone number.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def detail_hint
    'get_user reads a user in detail by ID or email: their other organizations, note and custom fields. ' \
      'search_tickets lists a user\'s tickets with customer "ID n".'
  end

  def row_includes
    [:organization]
  end

  # The search syntax would read the plus and the brackets of a number the caller log does not know.
  def query
    return super if !phone_number?

    argument(:query).to_s.gsub(%r{\D+}, ' ').squish
  end

  def search_ids
    return super if caller_log_user_ids.empty?

    caller_log_user_ids[offset, limit + 1] || []
  end

  def phone_number?
    text = argument(:query).to_s.squish

    text.match?(PHONE) && text.count('0-9') >= PHONE_DIGITS
  end

  # Every user who shares the number, as a switchboard's number is shared: Cti::CallerId.lookup stops at 20.
  def caller_log_user_ids
    @caller_log_user_ids ||= begin
      number = Cti::CallerId.normalize_number(argument(:query).to_s) if phone_number?

      if number.present?
        Cti::CallerId.where(caller_id: number, level: 'known', object: 'User')
          .where.not(o_id: Service::EntityAttribute::NameMatch::NOBODY_ID)
          .group(:o_id).reorder(Arel.sql('MAX(id) DESC')).pluck(:o_id)
      else
        []
      end
    end
  end

  def row(user)
    {
      **visible_user_row(user),
      **CALL_FIELDS.select { |field| field_visible?(user, field) }.index_with { |field| user[field].to_s.squish.presence }.compact,
      organization: (Service::AI::Tool::Output::Organization.row(user.organization).content if user.organization && readable?(user.organization)),
      vip:          (true if user.vip && field_visible?(user, :vip)),
      active:       (false if !user.active),
    }.compact
  end

  def line(row)
    facts = [row[:email], *CALL_FIELDS.filter_map { |field| "#{field} #{row[field]}" if row[field] }, ('VIP' if row[:vip]), ('inactive' if row[:active] == false)].compact
    organization = row[:organization] && "organization #{row[:organization][:name]} (ID #{row[:organization][:id]})"

    ["- #{row[:name].to_s.squish}#{" (#{facts.join(', ')})" if facts.any?}", organization, "user ID #{row[:id]}"].compact.join(', ')
  end
end
