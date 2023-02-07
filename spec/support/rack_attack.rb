# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|

  # Rack attack has no rolling time periods. Make sure it works consistently
  #   also in slow CI situations.
  # See https://github.com/rack/rack-attack/issues/601
  config.around(:each, :rack_attack) do |example|
    freeze_time

    example.run
  end
end
