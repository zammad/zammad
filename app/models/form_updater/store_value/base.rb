# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::StoreValue::Base

  def can_handle_field?(field:, value:)
    false
  end

  def omit_field?(field:, value:)
    false
  end

  def store_value(field:, value:)
    raise OmitFieldError if omit_field?(field:, value:)

    map_value(field:, value:)
  end

  class OmitFieldError < StandardError; end
end
