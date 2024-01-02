# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::Handler

  def self.process(...)
    new(...).process
  end

  def type
    raise NotImplementedError
  end
end
