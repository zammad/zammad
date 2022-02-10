# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module TestFlags
  def wait_for_test_flag(flag, skip_clearing: false)
    wait.until { page.evaluate_script("window.testFlags.get('#{flag.gsub("'", "\\'")}', #{skip_clearing})") }
  end
end

RSpec.configure do |config|
  config.include TestFlags, type: :system
end
