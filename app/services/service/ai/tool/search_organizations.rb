# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::SearchOrganizations < Service::AI::Tool
  include Service::AI::Tool::Concerns::RecordSearch
  include Service::AI::Tool::Concerns::Sorting

  # The members as Organization#all_members has them, through the primary organization and the secondary ones, counted
  #   for a page at once: all_members joins both with a condition no index serves.
  MEMBER_COUNTS = <<~SQL.squish.freeze
    SELECT organization_id, COUNT(DISTINCT user_id) FROM (
      SELECT id AS user_id, organization_id FROM users WHERE organization_id IN (:ids)
      UNION
      SELECT user_id, organization_id FROM organizations_users WHERE organization_id IN (:ids)
    ) members
    GROUP BY organization_id
  SQL

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  ROW_SCHEMA = {
    type:       'object',
    properties: Service::AI::Tool::Output::Organization::SCHEMA[:properties].merge(
      **Service::AI::Tool::GetOrganization::OUTPUT_SCHEMA.dig(:properties, :organization, :properties).slice(:domain, :member_count, :active),
      vip: { type: 'boolean' },
    ),
    required:   %w[type id name member_count],
  }.freeze

  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      query:         { type: 'string', description: 'The words searched for.' },
      organizations: { type: 'array', items: ROW_SCHEMA },
      has_more:      { type: 'boolean' },
      next_cursor:   { type: 'string', description: 'Pass it as cursor, with the same query, for the next organizations.' },
    },
    required:   %w[query organizations has_more],
  }.freeze

  description 'Find organizations of Zammad — the inactive ones included — by words of their name or their domain, ' \
              'as Zammad\'s search finds them. Each row names the organization\'s ID, domain, VIP flag and number ' \
              'of members; the other tools take the ID, and get_organization reads an organization in detail. Pass ' \
              'next_cursor as cursor, with the same query, for the next organizations.'
  title 'Search organizations'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents
  searches

  parameter :query, type: :string, required: true, description: 'Words of a name or a domain, e.g. "Acme" or "acme.example".'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT, description: 'How many organizations to list.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next organizations.'
  sortable %w[name created_at updated_at], default: 'the active organizations first, the newest created first'
  # rubocop:enable Zammad/DetectTranslatableString

  private

  def model
    ::Organization
  end

  def result_key
    :organizations
  end

  def record_noun
    'organization'
  end

  def query_hint
    'Pass a name or a domain.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def detail_hint
    'get_organization reads an organization in detail by its ID: its note, custom fields and members. ' \
      'search_tickets lists an organization\'s tickets with organization "ID n".'
  end

  def row(organization)
    {
      **Service::AI::Tool::Output::Organization.row(organization).content,
      domain:       (organization.domain.to_s.squish.presence if field_visible?(organization, :domain)),
      vip:          (true if organization.vip && field_visible?(organization, :vip)),
      member_count: member_counts.fetch(organization.id, 0),
      active:       (false if !organization.active),
    }.compact
  end

  def member_counts
    @member_counts ||= ActiveRecord::Base.connection.select_rows(ActiveRecord::Base.sanitize_sql([MEMBER_COUNTS, { ids: page.map(&:id).presence || [0] }])).to_h
  end

  def line(row)
    facts = [("domain #{row[:domain]}" if row[:domain]), ('VIP' if row[:vip]), "#{row[:member_count]} #{'member'.pluralize(row[:member_count])}", ('inactive' if row[:active] == false)].compact

    "- #{row[:name]} (#{facts.join(', ')}), organization ID #{row[:id]}"
  end
end
