# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Says whom an MCP client works for: the token's user as a reference, and what decides what the user sees in Zammad —
#   the groups with their kind of access and the knowledge base level the token grants. The tools a client lists show
#   what the token may do, so no permissions. The harness knows its user.
class Service::AI::Tool::GetCurrentUser < Service::AI::Tool
  # The kinds of group access, the widest first; "full" holds all the others.
  GROUP_ACCESS = %w[full read create change overview].freeze

  LEVEL_TEXTS = {
    'editor'    => 'every answer, drafts included',
    'reader'    => 'the internally and publicly published answers',
    'published' => 'the published answers only',
  }.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      user:           Service::AI::Tool::Output::User::SCHEMA,
      organization:   Service::AI::Tool::Output::Organization::SCHEMA,
      locale:         { type: 'string', description: 'The user\'s language, e.g. "en-us".' },
      time_zone:      { type: 'string', description: 'The time zone of the times in the tools\' results.' },
      groups:         {
        type:        'array',
        description: 'The groups whose tickets the user works with, and how.',
        items:       {
          type:       'object',
          properties: {
            name:   { type: 'string', description: 'The group\'s name, its levels joined by " › ", as the group filter of search_tickets takes it.' },
            access: { type: 'array', items: { enum: GROUP_ACCESS } },
          },
          required:   %w[name access],
        },
      },
      knowledge_base: {
        enum:        Service::AI::Tool::Access::KnowledgeBaseLevel::LEVELS,
        description: 'What of the knowledge base the user may read at most: editor every answer, reader the internally ' \
                     'and publicly published ones, published the published ones only. Missing where there is no knowledge base.',
      },
    },
    required:   %w[user locale time_zone groups],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'Find out whom this connection to Zammad works for: the user, their organization, language and time ' \
              'zone, the groups whose tickets they work with and how, and how much of the knowledge base they may ' \
              'read. Call it when a question depends on who the user is, such as which groups they work in.'
  title 'Get current user'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  def execute
    Service::AI::Tool::Runtime::Result.ok(content, text:)
  end

  private

  def content
    @content ||= {
      user:           user_row.content,
      organization:   organization_row&.content,
      locale:         current_user.locale,
      time_zone:,
      groups:,
      knowledge_base: knowledge_base_level,
    }.compact
  end

  def user_row
    @user_row ||= Service::AI::Tool::Output::User.row(current_user)
  end

  def organization_row
    return if current_user.organization.nil?

    @organization_row ||= Service::AI::Tool::Output::Organization.row(current_user.organization)
  end

  def time_zone
    Service::AI::Tool::Output.time_zone
  end

  # Each group once, with every kind of access the user holds directly or through a role; "full" alone where it holds.
  def groups
    @groups ||= begin
      full     = current_user.group_ids_access('full')
      accesses = full.index_with { ['full'] }

      GROUP_ACCESS.drop(1).each do |access|
        (current_user.group_ids_access(access) - full).each { |id| (accesses[id] ||= []) << access }
      end

      Group.where(id: accesses.keys)
        .map { |group| { name: group.name.split('::').join(' › '), access: accesses[group.id] } }
        .sort_by { |group| group[:name].downcase }
    end
  end

  def knowledge_base_level
    Service::AI::Tool::Access::KnowledgeBaseLevel.of(current_user) if ::KnowledgeBase.active.exists?
  end

  def text
    [
      "Connected as #{user_row.text}, user ID #{current_user.id}#{" · organization #{organization_row.text}" if organization_row}.",
      "Language #{content[:locale]} · times in the tools' results are in #{time_zone}.",
      groups_text,
      (knowledge_base_text if knowledge_base_level),
    ].compact.join("\n")
  end

  def groups_text
    return 'Groups: none — the user works with no group\'s tickets.' if groups.empty? # rubocop:disable Zammad/DetectTranslatableString

    AI::PromptText.xml_text("Groups: #{groups.map { |group| "#{group[:name]} (#{group[:access].join(', ')})" }.join(' · ')}")
  end

  def knowledge_base_text
    "Knowledge base: #{knowledge_base_level} — #{LEVEL_TEXTS.fetch(knowledge_base_level)}."
  end
end
