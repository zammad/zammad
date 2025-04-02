# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::EmailAddress < CoreWorkflow::Attributes::Base
  def values
    @values ||= EmailAddress.pluck(:id)
  end
end
