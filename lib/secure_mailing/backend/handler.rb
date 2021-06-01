# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SecureMailing::Backend::Handler

  def self.process(*args)
    new(*args).process
  end
end
