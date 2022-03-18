# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

# Rails' constant auto-loading resolves to 'rails/initializable' instead
require 'zammad/application/initializer/session_store'

Zammad::Application::Initializer::SessionStore.perform
