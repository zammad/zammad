# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module HaveTimeTag
  extend RSpec::Matchers::DSL

  matcher :have_time_tag do
    match do |actual|
      actual.has_css?('time', **args) { |elem| elem[:datetime] == expected.utc.iso8601 || elem[:datetime] == expected.utc.iso8601(3) } # handle JS version with miliseconds too
    end

    def args
      hash = {}
      hash[:text] = @display if @display.present?
      hash
    end

    chain :displayed_as do |display|
      @display = display
    end

    failure_message do |actual|
      "Expected #{actual} to include #{@display || expected}"
    end

    failure_message_when_negated do |actual|
      "Expected #{actual} to not include published time element"
    end

    match_when_negated do |actual|
      actual.has_no_css?('time')
    end
  end
end

RSpec.configure do |config|
  config.include HaveTimeTag, type: :system
end
