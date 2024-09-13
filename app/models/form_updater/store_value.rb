# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue
  include Mixin::RequiredSubPaths

  class OmitFieldError < StandardError; end

  FIELD_RENAMING_MAP = {
    'articleSenderType' => 'formSenderType',
  }.freeze

  attr_reader :store_state_group_keys

  def initialize(store_state_group_keys)
    @store_state_group_keys = store_state_group_keys || []
  end

  def perform(field:, value:)
    field = FIELD_RENAMING_MAP[field] || field
    result = {}

    # If the field is in the skip keys and the value is a hash, handle it recursively
    if store_state_group_keys.include?(field) && value.is_a?(Hash)
      sub_result = {}

      value.each do |sub_field, sub_value|
        # Perform processing for each sub-field and merge the results
        sub_result.merge!(perform(field: sub_field, value: sub_value))
      end

      # Save the processed sub-fields inside the main field key
      result[field] = sub_result
    else
      begin
        # Handle complex fields via their handler.
        result[field] = if (handler = find_handler(field:, value:))
                          handler.store_value(field:, value:)

                        # Return the passed value for simple fields.
                        else
                          value
                        end
      rescue FormUpdater::StoreValue::Base::OmitFieldError
        # Skip omitted fields.
      end
    end

    result
  end

  private

  def find_handler(field:, value:)
    FormUpdater::StoreValue::Base
      .descendants
      .lazy
      .map(&:new)
      .find { |elem| elem.can_handle_field?(field:, value:) }
  end
end
