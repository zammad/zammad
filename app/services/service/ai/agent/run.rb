# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Agent::Run < Service::Base
  attr_reader :ai_agent, :agent_definition, :action_definition, :ticket, :article

  def initialize(ai_agent:, ticket:, article: nil)
    super()

    @ai_agent = ai_agent
    @agent_definition = ai_agent.execution_definition
    @action_definition = ai_agent.execution_action_definition
    @ticket = ticket
    @article = article
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'ai_provider', custom_error_message: __('AI provider is not configured.')).execute

    begin
      ai_agent_result = ai_agent_service_result
    rescue AI::Provider::OutputFormatError => e
      raise PermanentError, e.message
    rescue AI::Provider::ResponseError => e
      raise TemporaryError, e.message
    rescue => e # rubocop:disable Lint/DuplicateBranch
      raise PermanentError, e.message
    end

    ai_agent_perform_template = Service::AI::Agent::Run::Perform::Agent.new(ai_agent:, ai_result: ai_agent_result)

    begin
      ticket.perform_changes(ai_agent_perform_template, 'ai_agent', {
                               article_id: article&.id
                             })
    rescue => e
      Rails.logger.error "AI Agent '#{ai_agent.name}' with ID #{ai_agent.id} perform_changes failed for ticket #{ticket.id}."

      raise PermanentError, e.message
    end
  end

  private

  def ai_agent_service_result
    context = Service::AI::Agent::Run::Context.new(
      instruction_context:           agent_definition['instruction_context'],
      entity_object:                 ticket,
      entity_context:                agent_definition['entity_context'],
      entity_article:                article,
      placeholder_object_attributes: ai_agent.agent_type_object&.placeholder_field_names,
      type_enrichment_data:          ai_agent.type_enrichment_data,
    )

    prepared_instruction_context = context.prepare_instructions
    prepared_entity_context = context.prepare_entity

    AI::Service::AIAgent.new(
      context_data:       {
        ai_agent:,
        ticket:,
        role_description:    agent_definition['role_description'],
        instruction:         agent_definition['instruction'],
        instruction_context: prepared_instruction_context,
        entity_context:      prepared_entity_context,
        result_structure:    agent_definition['result_structure'],
      },
      additional_options: {
        json_response: json_response?
      }
    ).execute
  end

  def json_response?
    @json_response ||= agent_definition['result_structure'].present?
  end

  class PermanentError < StandardError; end
  class TemporaryError < StandardError; end
end
