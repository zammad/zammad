# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads one organization in detail, named by the ID another tool's row gives: its domain, whether its members see each
#   other's tickets, what its record notes — the VIP flag, the note and the custom fields, as get_ticket gives them
#   (Service::AI::Tool::Output::Record) —, and its members: how many, and in the detailed layer the first of them, as
#   Zammad's own pages list them. Each field only as the organization's policy shows it.
class Service::AI::Tool::GetOrganization < Service::AI::Tool
  MEMBER_ROWS = 10

  DETAIL_FIELDS = %i[domain domain_assignment shared].freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  MEMBER_SCHEMA = Service::AI::Tool::Output::User::SCHEMA.merge(
    properties: Service::AI::Tool::Output::User::SCHEMA[:properties].merge(vip: { type: 'boolean' }, active: { const: false }),
  ).freeze

  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      organization: {
        type:       'object',
        properties: Service::AI::Tool::Output::Organization::SCHEMA[:properties].merge(
          domain:            { type: 'string', description: 'The email domain of its members.' },
          domain_assignment: { type: 'boolean', description: 'Whether a new user with an email of the domain joins the organization.' },
          shared:            { type: 'boolean', description: 'Whether its members see each other\'s tickets.' },
          active:            { const: false, description: 'Only where the organization is inactive.' },
          member_count:      { type: 'integer' },
          members:           { type: 'array', description: 'The first members, in the detailed layer.', items: MEMBER_SCHEMA },
          **Service::AI::Tool::Output::Record::SCHEMA[:properties],
        ),
        required:   %w[type id name member_count],
      },
    },
    required:   %w[organization],
  }.freeze

  description 'Read one organization of Zammad in detail, by organization_id — a ticket\'s organization as ' \
              'get_ticket names it, or one another tool listed, such as search_organizations, which finds one by ' \
              'name: its domain, VIP flag, note and custom fields, whether its members see each other\'s tickets, ' \
              'and its members: how many, and the first 10 by name and email. With response_format "concise" ' \
              'without the free-text fields and the member list.',
              harness: 'Only an organization a tool returned here or the agent named by ID.'
  title 'Get organization'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents

  loads :organization, type: ::Organization, named: true, starting: false

  parameter :response_format, type: :string, enum: %w[detailed concise], default: 'detailed',
                              description: 'detailed: everything, the first members included. concise: without the free-text fields and the members.'

  def execute
    Service::AI::Tool::Runtime::Result.ok({ organization: content }, text:)
  end

  private

  def concise?
    argument(:response_format) == 'concise'
  end

  def content
    @content ||= {
      **Service::AI::Tool::Output::Organization.row(organization).content,
      **details,
      active:       (false if !organization.active),
      member_count:,
      members:      (member_rows if !concise?),
      **(record&.content || {}),
    }.compact
  end

  def details
    @details ||= DETAIL_FIELDS.select { |field| field_visible?(organization, field) }.index_with { |field| detail_value(field) }.compact
  end

  def detail_value(field)
    value = organization[field]

    value.is_a?(String) ? value.squish.presence : value
  end

  # As GraphQL's members and their total count: through the primary organization and the secondary ones, each member
  #   once, in the order the organization's page shows them.
  def member_count
    @member_count ||= organization.all_members.count
  end

  # @return [Array<Hash>] each member's row with what tells them apart
  def member_rows
    @member_rows ||= organization.all_members.limit(MEMBER_ROWS).select { |member| readable?(member) }.map do |member|
      { **visible_user_row(member), vip: (true if member.vip && field_visible?(member, :vip)), active: (false if !member.active) }.compact
    end
  end

  # As get_ticket shows an organization's record: only where the policy shows the whole record.
  def record
    return @record if defined?(@record)

    @record = if Pundit.policy(current_user, organization).show? == true
                Service::AI::Tool::Output::Record.summary(organization, user: current_user, source: 'organization', concise: concise?)
              end
  end

  def text
    [
      AI::PromptText.xml_text(organization_line.squish),
      record&.text.presence,
      *members_texts,
    ].compact.join("\n\n")
  end

  def organization_line
    [
      "Organization #{content[:name]} (ID #{organization.id})",
      ("domain #{content[:domain]}" if content[:domain]),
      ('new users of the domain join it' if content[:domain_assignment]),
      ('members see each other\'s tickets' if content[:shared]),
      ('inactive' if content[:active] == false),
      *record&.facts,
      "#{member_count} #{'member'.pluralize(member_count)}",
    ].compact.join(' · ')
  end

  def members_texts
    return [] if member_count.zero?
    return ['The detailed layer lists the first members.'] if concise? # rubocop:disable Zammad/DetectTranslatableString

    lines = member_rows.map { |member| member_line(member) }
    more  = member_count > MEMBER_ROWS ? "Members: the first #{MEMBER_ROWS} of #{member_count}." : 'Members:'

    [
      AI::PromptText.xml_text([more, *lines].join("\n")),
      'get_user reads a member in detail by email or ID: phone, mobile, note.',
    ]
  end

  def member_line(member)
    facts = [member[:email], ('VIP' if member[:vip]), ('inactive' if member[:active] == false)].compact

    "- #{member[:name].to_s.squish}#{" (#{facts.join(', ')})" if facts.any?}, user ID #{member[:id]}"
  end
end
