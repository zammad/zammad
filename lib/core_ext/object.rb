# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Object
  def to_utf8(**options)
    to_s.utf8_encode(**options)
  end
end
