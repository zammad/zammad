# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflow::Result::Hide < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:visibility][field] = 'hide'
    true
  end
end
