# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type::CustomAIAgent < AI::Agent::Type

  def name
    __('Custom AI Agent')
  end

  def description
    __('This is a custom AI Agent type that allows full control over all of its parts. You can define the role description, instruction and its context, entity context, result structure, and action definition.')
  end

  def custom
    true
  end

  def form_schema
    [
      {
        step:   'definition',
        help:   __('For examples, please refer to the built-in AI agent types or our documentation. This is a highly advanced feature and should be used with caution.'),
        fields: [
          {
            name:        'definition::role_description',
            display:     __('Role description'),
            tag:         'textarea',
            rows:        5,
            placeholder: __('Enter the role description of the AI agent.'),
            help:        __('The description defines the role of the AI agent. It is used to describe its purpose and behavior.'),
            noHints:     true,
          },
          {
            name:        'definition::instruction',
            display:     __('Instruction'),
            tag:         'textarea',
            rows:        10,
            placeholder: __('Enter the instruction for the AI agent.'),
            help:        __('The text defines the instruction for the AI agent. It is used to guide it and tell it what to do.'),
            noHints:     true,
          },
          {
            name:    'definition::result_structure',
            display: __('Result structure'),
            tag:     'code_editor',
            help:    __('The structure is a JSON object that defines the result format to be returned by the AI agent.'),
            noHints: true,
          },
        ],
      },
      {
        step:   'instruction_context',
        fields: [
          {
            name:    'definition::instruction_context::object_attributes',
            display: __('Instruction context'),
            tag:     'code_editor',
            help:    __('The context is a JSON object that contains additional object attribute information for the AI agent. You can provide any object in the system, which will be included in the instruction.'),
            noHints: true,
          },
        ],
      },
      {
        step:   'entity_context',
        fields: [
          {
            name:    'definition::entity_context',
            display: __('Entity context'),
            tag:     'code_editor',
            help:    __('The context is a JSON object that defines what information about the current entity will be provided to the AI agent.'),
            noHints: true,
          },
        ],
      },
      {
        step:   'action_definition',
        fields: [
          {
            name:    'action_definition',
            display: __('Action definition'),
            tag:     'code_editor',
            help:    __('The definition is a JSON object that defines the action to be performed by the AI agent.'),
            noHints: true,
          },
        ],
      },
    ]
  end

  def action_definition
    {}
  end

  private

  def role_description
    ''
  end

  def instruction
    ''
  end

  def instruction_context
    {}
  end

  def entity_context
    {}
  end

  def result_structure
    {}
  end

end
