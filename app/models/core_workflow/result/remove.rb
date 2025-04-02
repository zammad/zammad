# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::Remove < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:visibility][field] = 'remove'
    true
  end
end
