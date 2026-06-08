# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Legacy settings, not used anymore. Keep for backwards compatibility.
class Rails::Application::Configuration
  def db_null_byte
    ActiveSupport::Deprecation.new.warn('Rails.application.config.db_null_byte is deprecated and will be removed in Zammad 8.0. Since PostgreSQL is the only supported database, this value is always false.')

    false
  end

  def db_case_sensitive
    ActiveSupport::Deprecation.new.warn('Rails.application.config.db_case_sensitive is deprecated and will be removed in Zammad 8.0. Since PostgreSQL is the only supported database, this value is always true.')

    true
  end

  def db_like
    ActiveSupport::Deprecation.new.warn('Rails.application.config.db_like is deprecated and will be removed in Zammad 8.0. Since PostgreSQL is the only supported database, this value is always ILIKE.')

    'ILIKE'
  end

  def db_column_array
    ActiveSupport::Deprecation.new.warn('Rails.application.config.db_column_array is deprecated and will be removed in Zammad 8.0. Since PostgreSQL is the only supported database, this value is always true.')

    true
  end
end
