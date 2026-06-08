# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Rails enables YJIT by default. Provide a way to disable it in case of issues.
if ActiveModel::Type::Boolean.new.cast(ENV['ZAMMAD_DISABLE_YJIT'])
  Rails.application.config.yjit = false
end
