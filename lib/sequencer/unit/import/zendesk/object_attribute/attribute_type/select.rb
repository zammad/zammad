# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Select < Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base

  def init_callback(object_attribte)
    @data_option.merge!(
      default: '',
      options: options(object_attribte),
    )
  end

  private

  def data_type(...)
    'select'
  end

  def options(object_attribte)
    object_attribte.custom_field_options.to_h { |entry| [entry['value'], entry['name']] }
  end
end
