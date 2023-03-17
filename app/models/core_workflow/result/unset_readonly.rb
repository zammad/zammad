# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::UnsetReadonly < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:readonly][field] = false
    true
  end
end
