# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module TestFlags
  def wait_for_test_flag(flag, skip_clearing: false)
    wait.until { page.evaluate_script("window.testFlags && window.testFlags.get('#{flag.gsub("'", "\\'")}', #{skip_clearing})") }
  end

  def wait_for_gql(filename, skip_clearing: false)
    gql = File.read(Rails.root.join("app/frontend/#{filename}"))
    operation = %r{^\w+ \w+}.match(gql).to_s
    wait_for_test_flag("__gql #{operation}", skip_clearing: skip_clearing)
  end
end

RSpec.configure do |config|
  config.include TestFlags, type: :system
end
