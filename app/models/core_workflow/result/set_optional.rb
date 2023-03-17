# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::SetOptional < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:mandatory][field] = false
    true
  end
end
