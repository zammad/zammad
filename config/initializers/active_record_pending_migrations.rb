# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

if %w[1 true].include? ENV['RAILS_CHECK_PENDING_MIGRATIONS']
  ActiveRecord::Migration.check_all_pending!

  # Staged addon packages of container images must be fully applied as well.
  #   Deferred, because app constants must not be autoloaded while initializers run.
  Rails.application.config.after_initialize do
    Package.check_staged_packages_applied!
  end
end
