# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::Handler

  def self.process(*args)
    new(*args).process
  end
end
