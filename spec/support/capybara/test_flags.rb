# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module TestFlags
  def wait_for_test_flag(flag, skip_clearing: false)
    begin
      wait.until { page.evaluate_script("window.testFlags && window.testFlags.get('#{flag.gsub("'", "\\'")}', #{skip_clearing})") }
    rescue Selenium::WebDriver::Error::TimeoutError
      raise "Test flag #{flag} not set"
    end
  end

  def wait_for_gql(filename, number: 1, skip_clearing: false)
    gql = Rails.root.join("app/frontend/#{filename}").read
    operation = %r{^\w+ \w+}.match(gql).to_s
    wait_for_test_flag("__gql #{operation} #{number}", skip_clearing: skip_clearing)
  end

  def wait_for_query(name, number: 1, skip_clearing: false)
    wait_for_test_flag("__gql query #{name} #{number}", skip_clearing: skip_clearing)
  end

  def wait_for_mutation(name, number: 1, skip_clearing: false)
    wait_for_test_flag("__gql mutation #{name} #{number}", skip_clearing: skip_clearing)
  end

  def wait_for_subscription_update(name, number: 1, skip_clearing: false)
    wait_for_test_flag("__gql subscription #{name} #{number}", skip_clearing: skip_clearing)
  end

  def wait_for_subscription_start(name, skip_clearing: true)
    wait_for_test_flag("__gql subscription #{name} start", skip_clearing: skip_clearing)
  end

  def wait_for_form_to_settle(form)
    wait_for_test_flag("#{form}.settled")
  end

  def wait_for_form_updater(form_updater_call_number = 1)
    wait_for_gql('shared/components/Form/graphql/queries/formUpdater.graphql', number: form_updater_call_number)
  end

  def wait_for_form_autofocus(form)
    wait_for_test_flag("#{form}.focused")
  end
end

RSpec.configure do |config|
  config.include TestFlags, type: :system
end
