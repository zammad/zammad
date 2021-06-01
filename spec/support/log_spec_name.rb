# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.configure do |config|

  config.prepend_before(:example) do |example|
    Rails.logger.info "=== running RSpec example '#{example.metadata[:full_description]}'"
  end
end
