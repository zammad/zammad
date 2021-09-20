# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::SetReadonly < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:readonly][field] = true
    true
  end
end
