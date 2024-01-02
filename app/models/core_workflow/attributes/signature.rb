# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::Signature < CoreWorkflow::Attributes::Base
  def values
    @values ||= Signature.pluck(:id)
  end
end
