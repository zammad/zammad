# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

##
# AI::Agent is a model that represents an AI agent with different strcutre parts:
#
# Definition:
#
# `role_description``: 'You have the role of doing something.',
# `instruction``: '- You should do this.
# - You should the other things.
# - ...',
# `instruction_context`: {
#    object_attributes: {
#      group_id: { '3' => 'Support team for technical issues', '4' => 'Sales team for customer inquiries' },
#      state_id: { '1' => 'New tickets awaiting assignment', '2' => 'Open tickets being worked on' },
#      custom_treeselect: { 'Category 1' => 'Main category for general issues', 'Category 1::Sub 1' => 'Subcategory for specific problems' },
#    }
#  }, // Informations which are added to the instructions (e.g. relevant group information for ticket group dispatching).
# `entity_context`: {
#    object_attributes: ['title', 'priority_id'], // All attributes of the object are possible.
#    articles: 'first|last|all', // The last article (current trigger article) or all articles of the object.
#  },
#  `result_structure`: {
#    group_id: 'integer',
#    is_real_question: 'boolean',
#  }, // JSON-Result structure is optional, it can also only be text.
#
# Action definition:
#
# The `ai_agent_result.example` will be replaced with the value from the AI service call, but also static values
# are possible.
#
# `mapping`: {
#   'ticket.group_id' => {
#     'value' => '#{ai_agent_result.group_id}'
#   },
# }, // Mapping of the result to the object attributes in perform changes syntax style.
#
# `conditions`: [
#   {
#     condition: {
#       is_real_question: false
#     },
#     mapping: {
#       'ticket.state' => {
#         'value' => 'closed'
#       },
#     }
#   }
# ], // Conditions are optional, they are used to check if the mapping should be executed.
#
# The mappings from the condition will be added to the general mapping and executed together.
#

class AI::Agent < ApplicationModel
  include ChecksHtmlSanitized
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include EnsuresNoRelatedObjects
  include AI::Agent::Assets
  include ChecksClientNotification

  PERFORMABLE_PATH = ['ai.ai_agent', 'ai_agent_id'].freeze

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :note, length: { maximum: 250 }
  validates :agent_type, inclusion: { in: AI::Agent::Type.available_types.map { |t| t.name.demodulize }, allow_blank: true }

  sanitized_html :note

  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

  ensures_no_related_objects_path(*PERFORMABLE_PATH)

  class << self
    def from_performable(input)
      where(active: true).find_by id: from_performable_id(input)
    end

    def from_performable_id(input)
      data = input.respond_to?(:perform) ? input.perform : input
      data.dig(*PERFORMABLE_PATH)
    end

    # Used by ObjectManager::Attribute.attribute_to_references_hash to
    # check which attributes cannot be deleted because they are used in AI agents.
    #
    # @return [Hash] a hash with the attribute name as key and the AI agent names as values
    #
    #   {'ticket.custom_textfield' => { 'AI Agent' => ['Test AI Agent', 'Test AI Agent 2'] } }
    #
    def object_attribute_dependencies
      all.each_with_object({}) do |agent, result|
        type = agent.agent_type_object
        next if !type

        deps = type.object_attribute_dependencies
        next if deps.blank?

        deps.each do |dep|
          key = "#{type.object_attribute_object_name.downcase}.#{dep}"
          result[key] ||= { __('AI Agent') => [] }
          result[key][__('AI Agent')] << agent.name
        end
      end
    end
  end

  def execution_definition
    return definition if agent_type.blank?

    agent_type_object.execution_definition.deep_stringify_keys.deep_merge(definition)
  end

  def execution_action_definition
    return action_definition if agent_type.blank?

    agent_type_object.execution_action_definition.deep_stringify_keys.deep_merge(action_definition)
  end

  def agent_type_object
    @agent_type_object ||= agent_type_class&.new(
      type_enrichment_data:,
    )
  end

  private

  def agent_type_class
    return if agent_type.blank?

    "AI::Agent::Type::#{agent_type}".constantize
  end
end
