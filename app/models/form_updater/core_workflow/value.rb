# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Value < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:select].merge(perform_result[:fill_in]).each do |name, value|
      result[name] ||= {}

      result[name][:value] = value
    end
  end
end
