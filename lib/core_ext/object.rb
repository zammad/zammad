# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Object
  def to_utf8(**)
    to_s.utf8_encode(**)
  end
end
