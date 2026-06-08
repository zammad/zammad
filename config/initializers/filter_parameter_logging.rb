# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.

# From the Rails generator:
Rails.application.config.filter_parameters += %i[
  passw email secret token _key crypt salt certificate otp ssn cvv cvc
]

# Zammad extensions:
Rails.application.config.filter_parameters += %i[
  bind_pw credentials passphrase
  state.body state.article.body article.body article.attachments.data attachments.data body
]
Rails.application.config.filter_parameters += [
  %r{.+key}i,  # privateKey, apiKey, ...
  %r{.+cert}i, # idp_cert, idpCert, …
]

# NOTE: Besides this global logging filter, Zammad also masks/unmasks sensitive parameters in controllers,
#   which uses different logic. Check `app/controllers/application_controller/handles_sensitive_params.rb`
#   and other files overriding the `sensitive_attributes` method for details.`
