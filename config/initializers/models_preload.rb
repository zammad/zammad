# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Ensure all models are preloaded, as Zammad uses reflections
#   which rely on all model classes being present.
Rails.application.reloader.to_prepare do
  begin
    Models.all
  rescue ActiveRecord::StatementInvalid
    nil
  rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError => e
    warn e
    Zammad::SafeMode.continue_or_exit!
  end
end
