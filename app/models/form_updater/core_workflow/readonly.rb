# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::CoreWorkflow::Readonly < FormUpdater::CoreWorkflow::Backend
  def perform
    perform_result[:readonly].each do |name, readonly|
      result[name] ||= {}

      result[name][:disabled] = readonly
    end
  end
end
