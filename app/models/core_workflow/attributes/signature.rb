# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Attributes::Signature < CoreWorkflow::Attributes::Base
  def values
    @values ||= Signature.all.pluck(:id)
  end
end
