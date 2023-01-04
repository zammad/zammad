# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Service::Concerns::HandlesCoreWorkflow
  extend ActiveSupport::Concern

  included do
    def set_core_workflow_information(data, klass, screen = 'create')
      return if data[:screen].present? || klass.included_modules.exclude?(ChecksCoreWorkflow)

      data[:screen] = screen
    end
  end
end
