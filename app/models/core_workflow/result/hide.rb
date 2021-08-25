# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class CoreWorkflow::Result::Hide < CoreWorkflow::Result::Backend
  def run
    @result_object.result[:visibility][field] = 'hide'
    true
  end
end
