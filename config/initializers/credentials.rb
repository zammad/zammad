# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# Zammad does not use signed cookie mechanism of Rails, so skip credentials handling.
Rails.application.config.secret_key_base = 'not_used_in_zammad'
