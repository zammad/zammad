# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::SetOptional < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:mandatory][field] = false
    true
  end
end
