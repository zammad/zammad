# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Agent::Type::TicketTextExtractor < AI::Agent::Type
  include AI::Agent::Type::Concerns::HasObjectAttributeList

  object_attribute_list_data_types 'input', 'textarea', 'integer', 'select', 'tree_select'
  object_attribute_list_object_name 'Ticket'
  object_attribute_list_exclude_internal true

  def name
    __('Ticket Text Extractor')
  end

  def description
    __('This type of AI agent can extract text from incoming tickets based on custom rules and store it into an object attribute.')
  end

  def placeholder_field_names
    %w[
      extracted_text
      extraction_rules
      priority_rules
      articles
    ]
  end

  def form_schema
    extraction_rules = {
      name:        'type_enrichment_data::extraction_rules',
      display:     __('Extraction rules'),
      tag:         'textarea',
      rows:        10,
      placeholder: __('Enter the extraction rules for the AI agent.'),
      help:        __('The rules instruct the AI agent on how to extract text from incoming tickets. Make sure to include a couple of example formats, and any additional instructions necessary.'),
      noHints:     true,
    }

    [
      {
        step:   'meta',
        errors: object_attributes_available? ? nil : [__('No suitable object attributes found, please add one of the supported types first: %s'), self.class.object_attribute_data_types.join(', ')],
        fields: [
          {
            name:      'type_enrichment_data::extracted_text',
            display:   __('Target Attribute for Extracted Text'),
            tag:       'select',
            help:      __('Select the attribute whose value will be automatically set by the AI agent.'),
            options:   object_attribute_list,
            disabled:  !object_attributes_available?,
            translate: true,
          },
        ],
      },
      {
        condition: 'extracted_text.options',
        step:      'instruction_context',
        help:      __('Choose which attribute values will be considered when extracting text from tickets. If you want to limit it to specific options, please select at least two below. Make sure the options have clear names and optional descriptions, as that would comprise the context provided to the AI agent.'),
        fields:    [
          {
            name:                                    'definition::instruction_context::object_attributes::placeholder.extracted_text',
            display:                                 '',
            tag:                                     'object_attribute_options_context',
            default:                                 {},
            limit_label:                             __('Limit values and provide optional descriptions'),
            limit_description:                       __('All values will be considered for extracted text from tickets.'),
            table_label:                             __('Available Values'),
            show_description:                        true,
            object_attribute_name:                   '',
            object_attribute_object:                 'Ticket',
            related_object_attribute_selection_name: 'type_enrichment_data::extracted_text',
          }
        ],
      },
      {
        step:   'extraction_rules',
        help:   __('Define the extraction rules for the AI agent, e.g. how to identify target text. For examples, please refer to our documentation.'),
        fields: [
          {
            condition: 'extracted_text.options',
            null:      true,
            default:   "Extract name of the affected product from the input.

The value may be one of the listed values (exact match), or one that resembles one of the listed values (partial match).

Take only the product name as the value, without any additional text.",
            **extraction_rules,
          },
          {
            condition: '!extracted_text.options',
            default:   "Extract value for an order number from the input.

The value may be provided in one of the following formats:
- Order#1234567
- Order No: 1234567
- Order number: 1234567

Take only the number as the value, without any additional text.",
            **extraction_rules,
          },
        ],
      },
      {
        step:   'priority_rules',
        help:   __('Define the prioritization rules for the AI agent, e.g. how to choose between multiple occurrences of the target text. For examples, please refer to our documentation.'),
        fields: [
          {
            name:        'type_enrichment_data::priority_rules',
            display:     __('Priority rules'),
            tag:         'textarea',
            rows:        10,
            placeholder: __('Enter the priority rules for the AI agent.'),
            help:        __('The rules instruct the AI agent on how to prioritize multiple matches of the extracted text. Make sure to include a couple of example formats, and any additional instructions necessary.'),
            noHints:     true,
            default:     "If multiple matches are found, prioritize based on the following rules:
- If one of the matches is in the ticket title, prioritize that one.
- If there are multiple matches in the same article, prioritize the one that appears first in the text.

Always return only one match."
          },
        ],
      },
      {
        step:   'extra_configuration',
        help:   __('Define which ticket article(s) should be analyzed.'),
        fields: [
          {
            name:    'type_enrichment_data::articles',
            display: __('Article(s) to analyze'),
            tag:     'select',
            help:    __('Select the ticket article(s) that should be analyzed by the AI agent.'),
            note:    __('In the trigger context, the last article will always be the one that activated the trigger.'),
            options: {
              'first' => __('First article (oldest)'),
              'last'  => __('Last article (newest)'),
              'all'   => __('All articles'),
            },
            default: 'last',
          },
        ],
      },
    ]
  end

  def action_definition
    {
      # rubocop:disable Lint/InterpolationCheck
      mapping: {
        'ticket.#{placeholder.extracted_text}' => {
          'value' => '#{ai_agent_result.#{placeholder.extracted_text}}'
        },
      },
      # rubocop:enable Lint/InterpolationCheck
    }
  end

  def role_description
    'Your task is to extract text from an incoming ticket.' # rubocop:disable Zammad/DetectTranslatableString
  end

  def instruction
    "\#{placeholder.extraction_rules}

\#{placeholder.priority_rules}

Apply the following principles when extracting text:

- Ignore irrelevant information (e.g. personal anecdotes, small talk, signatures, out-of-office notifications).
- Exclude segments that don't contribute any meaningful content (e.g. greetings, farewells).
- Never insert personal opinions about the conversation or elaborate on the answer.
- Never explain your given answer.
- If there is no match identified in the ticket, return an empty string.
- Only answer with the recognized value in the \"\#{placeholder.extracted_text}\" field inside the JSON structure."
  end

  def entity_context
    {
      object_attributes: ['title'],
      articles:          "\#{placeholder.articles}",
    }
  end

  def result_structure
    {
      '#{placeholder.extracted_text}': 'string',
    }
  end
end
