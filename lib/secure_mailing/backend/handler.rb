# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::Handler

  def self.process(*args)
    new(*args).process
  end
end
