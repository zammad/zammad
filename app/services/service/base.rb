# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::Base
  def execute
    raise NotImplementedError
  end
end
