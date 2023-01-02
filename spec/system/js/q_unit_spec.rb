# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'QUnit', authenticated_as: false, set_up: true, time_zone: 'Europe/London', type: :system do
  matcher :pass_qunit_test do
    match do
      actual.has_css?('.total', wait: 120)

      actual.has_css? '.result .failed', text: '0', wait: 0
    end

    failure_message do
      messages = actual
        .all('.qunit-assert-list li.fail')
        .map { |elem| "> #{failure_name(elem)}\n#{failure_source(elem)}" }
        .join("\n")

      "Failed #{failed_count} out of #{total_count}:\n#{messages}"
    end

    def failure_source(row)
      row
        .find('.test-source pre')
        .text
        .strip
        .lines[0, 2]
        .reject { |line| line.include? 'qunit-' }
        .join
    end

    def failure_name(row)
      row
        .find('.test-message')
        .text
        .strip
    end

    def failed_count
      actual.find('.result .failed').text
    end

    def total_count
      actual.find('.result .total').text
    end
  end

  files = if (basename = ENV['QUNIT_TEST'])
            [basename]
          else
            Pathname
              .glob('public/assets/tests/qunit/*.js')
              .map { |elem| elem.basename(elem.extname).to_s }
              .sort
          end

  files.each do |elem|
    it elem.humanize do
      visit "/tests_#{elem}"
      expect(page).to pass_qunit_test
    end
  end
end
