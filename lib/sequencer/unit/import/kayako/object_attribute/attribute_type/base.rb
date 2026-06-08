# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  attr_reader :attribute, :default_language, :model_class

  def initialize(attribute, default_language, model_class = nil)
    @attribute = attribute
    @default_language = default_language
    @model_class = model_class
  end

  def config
    {
      display:       attribute['title'],
      data_type:     data_type,
      data_option:   data_option,
      editable:      true,
      active:        attribute['is_enabled'],
      screens:       screens,
      position:      attribute['sort_order'],
      created_by_id: 1,
      updated_by_id: 1,
    }
  end

  def local_value(value)
    value
  end

  private

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
      shown:    attribute['is_customer_editable'] ? true : false,
      required: attribute['is_required_for_customers'] ? true : false,
    }
    agent = {
      shown:    true,
      required: attribute['is_required_for_agents'] ? true : false,
    }

    {
      create_middle: { 'ticket.customer' => customer, 'ticket.agent' => agent },
      edit:          { 'ticket.customer' => customer, 'ticket.agent' => agent },
    }
  end

  def data_option
    {
      null: true,
      note: '',
    }.merge(data_type_specific_options)
  end

  def data_type_specific_options
    {}
  end

  def data_type
    attribute['type'].downcase
  end
end
