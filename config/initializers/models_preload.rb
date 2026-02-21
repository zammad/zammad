# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Ensure all models are preloaded, as Zammad uses reflections
#   which rely on all model classes being present.
Rails.application.reloader.to_prepare do
  # Skip models preload during asset precompilation (no DB needed)
  next if Zammad::Application.assets_precompile?

  begin
    Models.all
  rescue ActiveRecord::StatementInvalid
    nil
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError => e
    warn e
    Zammad::SafeMode.continue_or_exit!
  end
end
