# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.

# From the Rails generator:
Rails.application.config.filter_parameters += %i[
  passw email secret token _key crypt salt certificate otp ssn cvv cvc
]

# Zammad extensions:
Rails.application.config.filter_parameters += %i[
  bind_pw credentials state.body state.article.body article.body article.attachments.data attachments.data body
]
