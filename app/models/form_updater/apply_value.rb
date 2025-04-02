# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue
  include Mixin::RequiredSubPaths

  attr_reader :context, :data, :dirty_fields, :result

  def initialize(context:, data:, result:, dirty_fields: nil)
    @context = context
    @data    = data
    @dirty_fields = dirty_fields
    @result = result
  end

  FIELD_RENAMING_MAP = {
    'formSenderType' => 'articleSenderType',
    'article.type'   => 'articleType',
  }.freeze

  def perform(field:, config:, include_blank: false, parent_field: nil)
    # Skip fields without a configured value
    return if config['value'].blank? && !include_blank

    full_field_path = parent_field ? "#{parent_field}.#{field}" : field

    field = FIELD_RENAMING_MAP[full_field_path] || field
    result[field] ||= {}

    # Cache the field attribute
    field_attribute = ObjectManager::Attribute.get(object: 'Ticket', name: field)

    # Complex fields
    if (handler = find_handler(field:, field_attribute:))
      return handler.apply_value(field:, config:)
    end

    # Simple fields
    return if dirty_fields&.include?(field) && data[field].present?

    result[field][:value] = config['value']
  end

  private

  def find_handler(field:, field_attribute:)
    FormUpdater::ApplyValue::Base
      .descendants
      .lazy
      .map { |handler_class| handler_class.new(context:, data:, dirty_fields:, result:) }
      .find { |elem| elem.can_handle_field?(field:, field_attribute:) }
  end
end
