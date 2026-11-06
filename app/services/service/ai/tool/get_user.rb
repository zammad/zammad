# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads one user in detail, named by the ID or the email another tool's row gives: how to reach them, their
#   organizations, and what their record notes — the VIP flag, the note and the custom fields, as get_ticket gives them
#   for the ticket's customer (Service::AI::Tool::Output::Record). Each field only as the user's policy shows it.
class Service::AI::Tool::GetUser < Service::AI::Tool
  CONTACT_FIELDS = %i[phone mobile fax web].freeze

  # The ones a person is reached by, named also where they are not set, so that a missing number reads as missing.
  CALL_FIELDS = %i[phone mobile].freeze

  ORGANIZATION_ROWS = 10

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      user: {
        type:       'object',
        properties: Service::AI::Tool::Output::User::SCHEMA[:properties].merge(
          phone:                 { type: 'string' },
          mobile:                { type: 'string' },
          fax:                   { type: 'string' },
          web:                   { type: 'string' },
          active:                { const: false, description: 'Only where the user is inactive.' },
          organization:          Service::AI::Tool::Output::Organization::SCHEMA,
          organizations:         { type: 'array', description: 'The user\'s other organizations.', items: Service::AI::Tool::Output::Organization::SCHEMA },
          organizations_omitted: { type: 'integer', description: 'How many other organizations are left out.' },
          **Service::AI::Tool::Output::Record::SCHEMA[:properties],
        ),
        required:   %w[type id name],
      },
    },
    required:   %w[user],
  }.freeze

  description 'Read one user of Zammad in detail, by user_id or email — a ticket\'s customer or owner as get_ticket ' \
              'names them, or a user another tool listed, such as search_users, which finds one by name: how to ' \
              'reach them by email, phone and mobile, their organizations, the VIP flag, the note and the custom ' \
              'fields. With response_format "concise" without the free-text fields.',
              harness: 'Only a user a tool returned here or the agent named by email or ID.'
  title 'Get user'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents

  loads :user, type: ::User, named: true, starting: false

  parameter :response_format, type: :string, enum: %w[detailed concise], default: 'detailed',
                              description: 'detailed: everything, the free-text fields included. concise: without the free-text fields.'

  def execute
    Service::AI::Tool::Runtime::Result.ok({ user: content }, text:)
  end

  private

  def content
    @content ||= {
      **visible_user_row(user),
      **contact,
      active:                (false if !user.active),
      organization:          organization_rows.first&.content,
      organizations:         other_organization_rows.map(&:content).presence,
      organizations_omitted: (other_organizations.size - ORGANIZATION_ROWS if other_organizations.size > ORGANIZATION_ROWS),
      **(record&.content || {}),
    }.compact
  end

  def contact
    @contact ||= CONTACT_FIELDS.select { |field| field_visible?(user, field) }.index_with { |field| user[field].to_s.squish.presence }.compact
  end

  def primary_organization
    return @primary_organization if defined?(@primary_organization)

    @primary_organization = user.organization if user.organization && readable?(user.organization)
  end

  def other_organizations
    @other_organizations ||= user.organizations.where.not(id: user.organization_id).reorder(:name).select { |organization| readable?(organization) }
  end

  def organization_rows
    @organization_rows ||= primary_organization ? [Service::AI::Tool::Output::Organization.row(primary_organization)] : []
  end

  def other_organization_rows
    @other_organization_rows ||= other_organizations.first(ORGANIZATION_ROWS).map { |organization| Service::AI::Tool::Output::Organization.row(organization) }
  end

  # As get_ticket shows a customer's record: only where the policy shows the whole record.
  def record
    return @record if defined?(@record)

    @record = if Pundit.policy(current_user, user).show? == true
                Service::AI::Tool::Output::Record.summary(user, user: current_user, source: record_source, concise: argument(:response_format) == 'concise')
              end
  end

  # A customer's record reads as in get_ticket; anyone else's, such as an owner's, is no customer's.
  def record_source
    user.permissions?('ticket.customer') && !user.permissions?('ticket.agent') ? 'customer_record' : 'user_record'
  end

  def text
    [
      AI::PromptText.xml_text([user_line, organizations_line].compact.map(&:squish).join("\n")),
      record&.text.presence,
      (more_text if content[:organization] || content[:organizations]),
    ].compact.join("\n\n")
  end

  def user_line
    [
      "User #{content[:name]} (ID #{user.id})",
      content[:email] || ('no email' if field_visible?(user, :email)),
      *contact_facts,
      ('inactive' if content[:active] == false),
      *record&.facts,
    ].compact.join(' · ')
  end

  def contact_facts
    CONTACT_FIELDS.filter_map do |field|
      next "#{field} #{contact[field]}" if contact[field]

      "no #{field}" if CALL_FIELDS.include?(field) && field_visible?(user, field)
    end
  end

  def organizations_line
    return 'organization: none' if !content[:organization] && !content[:organizations]

    named = ->(part) { "#{part[:name]} (ID #{part[:id]})" }
    parts = [
      ("organization #{named.call(content[:organization])}" if content[:organization]),
      ("other organizations: #{content[:organizations].map(&named).join(', ')}" if content[:organizations]),
      ("and #{content[:organizations_omitted]} more" if content[:organizations_omitted]),
    ]

    parts.compact.join(' · ')
  end

  def more_text
    'get_organization reads an organization in detail by its ID: its domain, VIP flag, note and members.'
  end
end
