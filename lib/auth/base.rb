# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Auth
  class Base

    def initialize(config)
      @config = config
    end

    def valid?(_user, _password)
      raise "Missing implementation of method 'valid?' for class '#{self.class.name}'"
    end
  end
end
