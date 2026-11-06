# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Finds the organization a caller names by its ID, which every row of an organization carries.
class Service::AI::Tool::Locator::Organization < Service::AI::Tool::Locator
  locates ::Organization

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  PARAMETERS = {
    'organization_id' => { type: :integer, description: 'The ID of the organization, e.g. 3, as another tool\'s result names it.' },
  }.freeze

  NO_NAME             = 'Name the organization by its organization_id.'.freeze
  NOT_IN_CONVERSATION = 'Only an organization a tool returned here and an organization the agent named in their own ' \
                        'messages, by ID, can be read. Ask the agent before you read another one.'.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  def record_id
    arguments['organization_id']
  end

  # @param ids [Array<Integer>] the organizations the conversation may read anyway
  # @param texts [Array<String>] what the agent wrote in the conversation
  def named_by?(ids:, texts:, **)
    id = record_id
    return false if id.nil?

    (ids + texts.flat_map { |text| text.to_s.scan(ID_IN_TEXT).flatten.map(&:to_i) }).include?(id)
  end
end
