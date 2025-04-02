# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.dev/rubocop/cop/zammad/forbid_redis_client'

RSpec.describe RuboCop::Cop::Zammad::ForbidRedisClient, type: :rubocop do
  it 'accepts Zammad::Service::Redis.new' do
    expect_no_offenses('Zammad::Service::Redis.new')
  end

  it 'rejects Redis.new' do
    result = inspect_source('Redis.new')

    expect(result.first.cop_name).to eq('Zammad/ForbidRedisClient')
  end
end
