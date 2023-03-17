# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::Show < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:visibility][field] = 'show'
    true
  end
end
