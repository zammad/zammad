# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Kernel
  # No-op used to mark strings as translatable.
  def __(string)
    string
  end
end
