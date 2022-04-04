# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.after(:each, type: :system) do
    next if page.driver.browser.browser != :chrome

    errors = page.driver.browser.manage.logs.get(:browser).select { |m| m.level == 'SEVERE' && m.to_s =~ %r{EvalError|InternalError|RangeError|ReferenceError|SyntaxError|TypeError|URIError} }
    if errors.present?
      Rails.logger.error "JS ERRORS: #{errors.to_json}"
      errors.each do |error|
        puts "#{error.message}\n\n"
      end
    end

    expect(errors.length).to eq(0)
  end
end
