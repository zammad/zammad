# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Rails' constant auto-loading resolves to 'rails/initializable' instead
require 'zammad/application/initializer/db_preflight_check'

Rails.application.config.after_initialize do
  Zammad::Application::Initializer::DbPreflightCheck.perform
end
