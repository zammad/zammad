# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Skip database preflight check during asset precompilation (no DB needed)
return if Zammad::Application.assets_precompile?

# Rails' constant auto-loading resolves to 'rails/initializable' instead
require 'zammad/application/initializer/db_preflight_check'

Rails.application.config.after_initialize do
  Zammad::Application::Initializer::DbPreflightCheck.perform
end
