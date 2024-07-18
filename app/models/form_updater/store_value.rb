# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue
  include Mixin::RequiredSubPaths

  class OmitFieldError < StandardError; end

  FIELD_RENAMING_MAP = {
    'articleSenderType' => 'formSenderType',
  }.freeze

  def perform(field:, value:)
    field = FIELD_RENAMING_MAP[field] || field
    result = {}

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
