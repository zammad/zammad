# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

Rails.application.config.after_initialize do
  next if !Rails.const_defined?(:Server)
  next if !Rails.env.production?

  storage_provider = Setting.get('storage_provider')
  next if %w[DB File].include?(storage_provider)

  begin
    adapter = "Store::Provider::#{storage_provider}".constantize
    adapter.ping!
  rescue Store::Provider::S3::Error => e
    adapter.reset
    warn e.message
    warn "There was an error trying to use storage provider '#{storage_provider}'."
    warn 'Please check the storage provider configuration.'

    Zammad::SafeMode.continue_or_exit!
  end
end
