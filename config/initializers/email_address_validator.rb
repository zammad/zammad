# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

Rails.application.config.after_initialize do
  EmailAddressValidator::Config.configure(
    local_format:     :standard,
    local_encoding:   :unicode,
    host_local:       true,
    host_fqdn:        false,
    host_auto_append: false
  )
  EmailAddressValidator::Config.providers.clear
end
