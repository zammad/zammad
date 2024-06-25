# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue
  include Mixin::RequiredSubPaths

  attr_reader :context, :data, :meta, :result

  def initialize(context:, data:, meta:, result:)
    @context = context
    @data    = data
    @meta    = meta
    @result  = result
  end

  FIELD_RENAMING_MAP = {
    'formSenderType' => 'articleSenderType',
  }.freeze

  def perform(field:, config:)
    # Skip fields without a configured value
    return if config['value'].blank?

    field = FIELD_RENAMING_MAP[field] || field
    result[field] ||= {}

    # Cache the field attribute
    field_attribute = ObjectManager::Attribute.get(object: 'Ticket', name: field)

    # Complex fields
    FormUpdater::ApplyValue::Base.descendants.each do |handler_class|
      handler = handler_class.new(context:, data:, meta:, result:)
      return handler.apply_value(field:, config:) if handler.can_handle_field?(field:, field_attribute:)
    end

    # Simple fields
    return if meta[:dirty_fields]&.include?(field) && data[field].present?

    result[field][:value] = config['value']
  end
end
