# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/forbid_calling_service_directly'

RSpec.describe RuboCop::Cop::Zammad::ForbidCallingServiceDirectly, type: :rubocop do
  it 'allows calling execute' do
    expect_no_offenses('Service::Sample.execute(token: token)')
  end

  it 'allows chaining with_current_user and execute' do
    expect_no_offenses('Service::Sample.with_current_user(user).execute(token: token)')
  end

  it 'allows chaining other methods after execute' do
    expect_no_offenses('Service::Sample.execute(token: token).do_something_else')
  end

  it 'allows calling new on unrelated classes' do
    expect_no_offenses('AI::Service.new')
  end

  it 'forbids calling new on service classes' do
    expect_offense(<<~RUBY)
      Service::Sample.new(token: token)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Service classes can only be called with `execute` class method or by chaining `Service.with_current_user(user).execute`. Calling `new` is forbidden.
    RUBY
  end

  it 'forbids calling execute on an instanceo of the service classes' do
    expect_offense(<<~RUBY)
      Service::Sample.new(token: token).execute
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Service classes can only be called with `execute` class method or by chaining `Service.with_current_user(user).execute`. Calling `new` is forbidden.
    RUBY
  end

  it 'forbids calling with_current_user and never calling execute' do
    expect_offense(<<~RUBY)
      Service::Sample.with_current_user(user)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Service classes can only be called with `execute` class method or by chaining `Service.with_current_user(user).execute`. Calling `new` is forbidden.
    RUBY
  end
end
