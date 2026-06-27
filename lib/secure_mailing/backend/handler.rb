# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SecureMailing::Backend::Handler
  class SigningError < StandardError; end

  def self.process(...)
    new(...).process
  end

  def type
    raise NotImplementedError
  end
end
