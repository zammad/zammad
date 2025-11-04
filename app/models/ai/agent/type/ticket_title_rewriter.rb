# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type::TicketTitleRewriter < AI::Agent::Type

  def name
    __('Ticket Title Rewriter')
  end

  def description
    __('This type of AI agent can improve title of incoming tickets based on their content and topic.')
  end

  def role_description
    'Your job is to analyze ticket content and create a meaningful title for it.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def instruction
    "Stick to the following principles:

- Always preserve the original input language (do not translate).
- Summarize the provided content and come up with a suitable title.
- Ignore quoted emails or quoted content.
- Try to use a maximum of 50 characters.
- Do not explain your given answer.
- Only answer with the value in the \"title\" field inside the JSON structure."
  end

  def entity_context
    {
      object_attributes: ['title'],
      articles:          'first',
    }
  end

  def result_structure
    {
      title: 'string',
    }
  end

  def action_definition
    {
      mapping: {
        'ticket.title' => {
          'value' => '#{ai_agent_result.title}' # rubocop:disable Lint/InterpolationCheck
        },
      },
    }
  end
end
