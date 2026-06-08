# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/prefer_models_all'

RSpec.describe RuboCop::Cop::Zammad::PreferModelsAll, :aggregate_failures, type: :rubocop do

  it 'accepts Models.all.keys' do
    expect_no_offenses('Models.all.keys')
  end

  it 'accepts Models.all.keys.each' do
    expect_no_offenses('Models.all.keys.each { |model| puts model }')
  end

  it 'rejects ActiveRecord::Base.descendants' do
    expect_offense(<<~RUBY)
      ActiveRecord::Base.descendants
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.
    RUBY
    expect_correction(<<~RUBY)
      Models.all.keys
    RUBY
  end

  it 'rejects ActiveRecord::Base.descendants with line break' do
    expect_offense(<<~RUBY)
      ActiveRecord::Base
      ^^^^^^^^^^^^^^^^^^ Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.
        .descendants
    RUBY
    expect_correction(<<~RUBY)
      Models.all.keys
    RUBY
  end

  it 'rejects ActiveRecord::Base.descendants.each' do
    expect_offense(<<~RUBY)
      ActiveRecord::Base.descendants.each { |model| puts model }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.
    RUBY
    expect_correction(<<~RUBY)
      Models.all.keys.each { |model| puts model }
    RUBY
  end

  it 'rejects ::ActiveRecord::Base.descendants' do
    expect_offense(<<~RUBY)
      ::ActiveRecord::Base.descendants
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.
    RUBY
    expect_correction(<<~RUBY)
      Models.all.keys
    RUBY
  end

  it 'rejects ActiveRecord::Base.descendants.select' do
    expect_offense(<<~RUBY)
      ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(SomeModule) }
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer `Models.all.keys` over `ActiveRecord::Base.descendants` to avoid issues with eager loading.
    RUBY
    expect_correction(<<~RUBY)
      Models.all.keys.select { |c| c.included_modules.include?(SomeModule) }
    RUBY
  end
end
