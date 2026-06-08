# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::ObjectAttribute::Config < Sequencer::Unit::Base
  prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

  skip_any_action

  uses :resource, :sanitized_name, :model_class
  provides :config, :action

  def process
    if !data_type
      state.provide(:action, :skipped)
      return
    end

    state.provide(:config, provide_config)
  end

  private

  DATA_TYPE_MAP = {
    'custom_date'         => 'date',
    'custom_date_time'    => 'datetime',
    'custom_checkbox'     => 'boolean',
    'custom_dropdown'     => 'select',
    'custom_text'         => 'input',
    'custom_number'       => 'integer',
    'custom_paragraph'    => 'input',
    'custom_decimal'      => 'input', # Don't use 'integer' as it would cut off the fractional part.
    'custom_url'          => 'input',
    'custom_phone_number' => 'input',
    'default_ticket_type' => 'select',
  }.freeze

  DEFAULT_FIELD_NAME_MAP = {
    'ticket_type' => 'type',
  }.freeze

  def provide_config
    {
      object:        model_class.to_s,
      name:          DEFAULT_FIELD_NAME_MAP[resource['name']] || sanitized_name,
      display:       resource['label'],
      data_type:     data_type,
      data_option:   data_option,
      editable:      true,
      active:        true,
      screens:       screens,
      position:      resource['position'],
      created_by_id: 1,
      updated_by_id: 1,
    }
  end

  def data_type
    @data_type ||= DATA_TYPE_MAP[resource['type']]

    if !@data_type
      Rails.logger.debug { "The custom field type '#{resource['type']}' cannot be mapped to an internal field, skipping." }
      return
    end

    @data_type
  end

  def data_option
    {
      null: true,
      note: '',
    }.merge(data_type_options)
  end

  def data_type_options

    case data_type
    when 'date', 'datetime'
      {
        future: true,
        past:   true,
        diff:   0,
      }
    when 'boolean'
      {
        default: false,
        options: {
          true  => 'yes',
          false => 'no',
        },
      }
    when 'select'
      {
        default: '',
        options: options,
      }
    when 'input'
      case resource['type']
      when 'custom_phone_number'
        {
          type:      'tel',
          maxlength: 100,
        }
      when 'custom_url'
        {
          type:      'url',
          maxlength: 250,
        }
      else
        {
          type:      'text',
          maxlength: 255,
        }
      end
    when 'integer'
      {
        min: 0,
        max: 999_999_999,
      }
    else
      {}
    end
  end

  def screens
    return ticket_screens if model_class.to_s == 'Ticket'

    {
      create: { '-all-' => { shown: true } },
      edit:   { '-all-' => { shown: true } },
      view:   { '-all-' => { shown: true } },
    }
  end

  def ticket_screens
    customer = {
      shown: resource['customers_can_edit'] ? true : false,
      null:  resource['required_for_customers'] ? false : true,
    }
    agent = {
      shown: true,
      null:  resource['required_for_agents'] ? false : true,
    }

    {
      create_middle: { 'ticket.agent' => agent, 'ticket.customer' => customer },
      edit:          { 'ticket.agent' => agent, 'ticket.customer' => customer },
    }
  end

  def options
    resource['choices'].to_h do |choice|
      [choice, choice]
    end
  end
end
