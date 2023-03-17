# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Kernel
  # No-op used to mark strings as translatable.
  def __(string)
    string
  end
end
