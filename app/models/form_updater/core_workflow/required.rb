# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Required < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:mandatory].each do |name, required|
      result[name] ||= {}

      result[name][:required] = required && result[name][:show] && !result[name][:hidden]
    end
  end
end
