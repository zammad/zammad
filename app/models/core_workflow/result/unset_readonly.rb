# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::UnsetReadonly < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:readonly][field] = false
    true
  end
end
