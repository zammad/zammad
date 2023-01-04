# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::ObjectAttribute::AttributeType::Base
  attr_reader :attribute, :default_language

  def initialize(attribute, default_language)
    @attribute = attribute
    @default_language = default_language
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
    default = {
      view: {
        '-all-' => {
          shown: true,
          null:  true,
        },
        Customer: {
          shown: attribute['is_visible_to_customers'],
          null:  true,
        },
      },
      edit: {
        '-all-' => {
          shown: true,
          null:  true,
        },
        Customer: {
          shown: attribute['is_customer_editable'],
          null:  !attribute['is_required_for_customers'],
        },
      }
    }

    if attribute['is_required_for_agents']
      default[:edit]['ticket.agent'] = {
        shown:    true,
        required: true,
      }
    end

    default
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
