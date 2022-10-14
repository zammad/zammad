# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module TestFlags
  def wait_for_test_flag(flag, skip_clearing: false)
    wait.until { page.evaluate_script("window.testFlags && window.testFlags.get('#{flag.gsub("'", "\\'")}', #{skip_clearing})") }
  end

  def wait_for_gql(filename, number: 1, skip_clearing: false)
    gql = Rails.root.join("app/frontend/#{filename}").read
    operation = %r{^\w+ \w+}.match(gql).to_s
    wait_for_test_flag("__gql #{operation} #{number}", skip_clearing: skip_clearing)
  end

  def wait_for_form_to_settle(form)
    wait_for_test_flag("#{form}.settled")
  end
end

RSpec.configure do |config|
  config.include TestFlags, type: :system
end
