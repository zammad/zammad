# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|

  config.prepend_before do |example|
    Rails.logger.info "=== running RSpec example '#{example.metadata[:full_description]}'"
  end
end
