# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Object
  # Kept for third-party code only; no caller in this repository remains.
  def to_utf8(**)
    ActiveSupport::Deprecation.new.warn('Object#to_utf8 is deprecated and will be removed in Zammad 8.0. Please use TextEncoding.utf8_encode(object, **options) instead.')

    TextEncoding.utf8_encode(self, **)
  end
end
