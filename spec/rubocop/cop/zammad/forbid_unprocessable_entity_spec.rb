# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/forbid_unprocessable_entity'

RSpec.describe RuboCop::Cop::Zammad::ForbidUnprocessableEntity, type: :rubocop do

  it 'accepts Exceptions::UnprocessableContent' do
    expect_no_offenses("raise Exceptions::UnprocessableContent, 'message'")
  end

  it 'rejects and corrects Exceptions::UnprocessableEntity when raised' do
    expect_offense(<<~RUBY)
      raise Exceptions::UnprocessableEntity, 'message'
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Exceptions::UnprocessableContent` instead of the deprecated `Exceptions::UnprocessableEntity`.
    RUBY
    expect_correction(<<~RUBY)
      raise Exceptions::UnprocessableContent, 'message'
    RUBY
  end

  it 'rejects and corrects Exceptions::UnprocessableEntity when rescued' do
    expect_offense(<<~RUBY)
      begin
        do_something
      rescue Exceptions::UnprocessableEntity => e
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Exceptions::UnprocessableContent` instead of the deprecated `Exceptions::UnprocessableEntity`.
        handle(e)
      end
    RUBY
    expect_correction(<<~RUBY)
      begin
        do_something
      rescue Exceptions::UnprocessableContent => e
        handle(e)
      end
    RUBY
  end

  it 'rejects and corrects the fully qualified ::Exceptions::UnprocessableEntity' do
    expect_offense(<<~RUBY)
      raise ::Exceptions::UnprocessableEntity
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `Exceptions::UnprocessableContent` instead of the deprecated `Exceptions::UnprocessableEntity`.
    RUBY
    expect_correction(<<~RUBY)
      raise ::Exceptions::UnprocessableContent
    RUBY
  end
end
