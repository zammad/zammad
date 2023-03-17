# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Rails.application.config.after_initialize do
  EmailAddressValidator::Config.configure(
    local_format:     :standard,
    local_encoding:   :unicode,
    host_local:       true,
    host_fqdn:        false,
    address_size:     3..250, # EmailAdress#email database field is limited to 250 characters, User#email is 255
    host_auto_append: false
  )

  # Allow emails with very long local part. For example Google Docs notifications emails
  EmailAddressValidator::Local.send(:remove_const, :STANDARD_MAX_SIZE)
  EmailAddressValidator::Local.const_set(:STANDARD_MAX_SIZE, 200)

  EmailAddressValidator::Config.providers.clear
end
