# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type::TicketPrioritizer < AI::Agent::Type

  def name
    __('Ticket Prioritizer')
  end

  def description
    __('This type of AI agent can prioritize incoming tickets based on their content.')
  end

  def role_description
    'Your job is to analyze the current ticket content and assign the most appropriate priority based on the current topic and identified urgency.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def form_schema
    [
      { step:   'instruction_context',
        help:   __('Choose which priorities will be considered when prioritizing tickets. If you want to limit it to specific priorities, please select at least two below. Make sure the priorities have clear names and optional descriptions, as that would comprise the context provided to the AI agent.'),
        fields: [
          {
            name:                    'definition::instruction_context::object_attributes::priority_id',
            display:                 '',
            tag:                     'object_attribute_options_context',
            default:                 {},

            limit_label:             __('Limit priorities and provide optional descriptions'),
            limit_description:       __('All priorities will be considered for prioritizing tickets.'),
            table_label:             __('Available Priorities'),
            show_description:        true,

            object_attribute_name:   'priority_id',
            object_attribute_object: 'Ticket',
          },
        ] },
    ]
  end

  def instruction
    "Apply the following principles to identify the correct prioritization:

- Ignore irrelevant information (e.g. personal anecdotes, small talk, signatures, out-of-office notifications).
- Exclude segments that don't contribute any meaningful content (e.g. greetings, farewells).
- Never insert personal opinions about the conversation or elaborate on the answer.
- Never explain your given answer.
- Only answer with the value in the \"priority_id\" field inside the JSON structure."
  end

  def entity_context
    {
      object_attributes: ['title'],
      articles:          'last',
    }
  end

  def result_structure
    {
      priority_id: 'integer',
    }
  end

  def action_definition
    {
      mapping: {
        'ticket.priority_id' => {
          'value' => '#{ai_agent_result.priority_id}', # rubocop:disable Lint/InterpolationCheck
        },
      },
    }
  end
end
