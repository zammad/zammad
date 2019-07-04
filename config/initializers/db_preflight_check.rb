# Rails' constant auto-loading resolves to 'rails/initializable' instead
require_dependency 'zammad/application/initializer/db_preflight_check'

Zammad::Application::Initializer::DBPreflightCheck.perform
