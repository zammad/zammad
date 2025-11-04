# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AIAssistance::TextTools < Service::BaseWithCurrentUser
  attr_reader :input, :text_tool, :regeneration_of, :template_render_context

  def initialize(input:, text_tool:, current_user: nil, regeneration_of: nil, template_render_context: {})
    super(current_user:) if current_user.present?

    @input = input
    @text_tool = text_tool
    @regeneration_of = regeneration_of
    @template_render_context = template_render_context
  end

  def execute
    return if input.blank?

    Service::CheckFeatureEnabled.new(name: 'ai_assistance_text_tools').execute
    Service::CheckFeatureEnabled.new(name: 'ai_provider', custom_error_message: __('AI provider is not configured.')).execute

    raise ArgumentError, __('AI assistance text tool is invalid.') if !text_tool.is_a?(AI::TextTool)
    raise ArgumentError, __('AI assistance text tool is inactive.') if !text_tool.active?

    ai_text_tool_service = AI::Service::TextTool.new(
      current_user:,
      context_data:    {
        instruction:        rendered_text_tool_instruction,
        fixed_instructions: Setting.get('ai_assistance_text_tools_fixed_instructions'),
        input:,
        text_tool:,
      },
      regeneration_of:,
    )

    ai_text_tool_service.execute
  end

  private

  def rendered_text_tool_instruction
    @rendered_text_tool_instruction ||= NotificationFactory::Renderer.new(
      objects:  { user: current_user }.merge(template_render_context),
      template: text_tool.instruction,
      escape:   false
    ).render(debug_errors: false)
  end
end
