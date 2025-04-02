# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/ensures_time_zone_at_spec_top_level'

RSpec.describe RuboCop::Cop::Zammad::EnsuresTimeZoneAtSpecTopLevel, :aggregate_failures, type: :rubocop do
  context 'when type is system' do
    it 'allows time zone at top level' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'Test', type: :system, time_zone: 'Europe/London' do
          it 'is fine' do
            example
          end
        end
      RUBY
    end

    it 'rejects time zone at lower level' do
      expect_offense(<<~RUBY)
        RSpec.describe 'Test', type: :system do
          it 'is fine', time_zone: 'Europe/London' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ RSpec system tests (aka Capybara) should set custom time zones at top level only
            example
          end
        end
      RUBY
    end
  end

  context 'when type is not system' do
    it 'allows time zone at lower level if it is not a system/Capybara test' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe 'Test' do
          it 'is fine', time_zone: 'Europe/London' do
            example
          end
        end
      RUBY
    end
  end
end
