# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type::TicketGroupDispatcher < AI::Agent::Type

  def name
    __('Ticket Group Dispatcher')
  end

  def description
    __('This type of AI agent can dispatch incoming tickets into an appropriate group based on their content and topic.')
  end

  def form_schema
    [
      step:   'instruction_context',
      help:   __('Choose which groups will be considered for dispatching tickets. If you want to limit it to specific groups, please select at least two below. Make sure the groups have clear names and optional descriptions, as that would comprise the context provided to the AI agent.'),
      fields: [
        {
          name:                    'definition::instruction_context::object_attributes::group_id',
          display:                 '',
          tag:                     'object_attribute_options_context',

          limit_label:             __('Limit groups and provide optional descriptions'),
          limit_description:       __('All groups will be considered for dispatching tickets.'),
          table_label:             __('Available Groups'),
          show_description:        true,

          object_attribute_name:   'group_id',
          object_attribute_object: 'Ticket',
        },
      ],
    ]
  end

  def action_definition
    {
      mapping: {
        'ticket.group_id' => {
          'value' => '#{ai_agent_result.group_id}' # rubocop:disable Lint/InterpolationCheck
        },
      },
    }
  end

  def instruction
    "Apply the following principles to identify the correct group:

- Ignore irrelevant information (e.g. personal anecdotes, small talk, signatures, out-of-office notifications).
- Exclude segments that don't contribute any meaningful content (e.g. greetings, farewells).
- Do not insert personal opinions about the conversation or elaborate on the answer.
- Do not explain your given answer.
- Only answer with the value in the \"group_id\" field inside the JSON structure."
  end

  def role_description
    'You are a ticket routing specialist who analyzes ticket content and assigns tickets to the most appropriate group based on the topic and context.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def result_structure
    {
      group_id: 'integer',
    }
  end
end
