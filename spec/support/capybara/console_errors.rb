# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.after(:each, type: :system) do
    next if page.driver.browser.browser != :chrome

    logs   = page.driver.browser.logs.get(:browser)
    errors = logs.select { |m| m.level == 'SEVERE' && m.to_s =~ %r{EvalError|InternalError|RangeError|ReferenceError|SyntaxError|TypeError|URIError} }

    # FIXME: Ignore certain unexplained JS errors that happen at the end of a test.
    #   - 127865:14 Uncaught TypeError: Cannot read properties of undefined (reading 'sort')
    errors = errors.filter { |e| e.message !~ %r{Uncaught TypeError: Cannot read properties of undefined \(reading 'sort'\)$} }

    if errors.present?
      Rails.logger.error "JS ERRORS: #{errors.to_json}"
      errors.each do |error|
        puts "#{error.message}\n\n"
      end

      Rails.root.join('log/browser.log').write(logs.map { |l| "#{l.level}|#{l.message}" }.join("\n"))
    end

    expect(errors.length).to eq(0)
  end
end
