# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Rails' constant auto-loading resolves to 'rails/initializable' instead
require 'zammad/application/initializer/session_store'

Zammad::Application::Initializer::SessionStore.perform
