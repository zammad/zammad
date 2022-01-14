# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Kernel
  # No-op used to mark strings as translatable.
  def __(string)
    string
  end
end
