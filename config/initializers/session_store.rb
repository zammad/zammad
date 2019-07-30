# Rails' constant auto-loading resolves to 'rails/initializable' instead
require_dependency 'zammad/application/initializer/session_store'

Zammad::Application::Initializer::SessionStore.perform
