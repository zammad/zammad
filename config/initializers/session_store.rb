# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

# Rails' constant auto-loading resolves to 'rails/initializable' instead
require 'zammad/application/initializer/session_store'

Zammad::Application::Initializer::SessionStore.perform
