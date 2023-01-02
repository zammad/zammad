# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::EmailAddress < CoreWorkflow::Attributes::Base
  def values
    @values ||= EmailAddress.all.pluck(:id)
  end
end
