# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::SetMandatory < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:mandatory][field] = true
    true
  end
end
