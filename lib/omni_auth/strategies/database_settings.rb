# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# OmniAuth builds each strategy only once, so the settings are read per request
# on the strategy's own copy of the options.
module OmniAuth::Strategies::DatabaseSettings
  def setup_phase
    options.deep_merge!(self.class.setup)

    super
  end
end
