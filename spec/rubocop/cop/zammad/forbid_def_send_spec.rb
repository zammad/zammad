# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require_relative '../../../../.rubocop/cop/zammad/forbid_def_send'

RSpec.describe RuboCop::Cop::Zammad::ForbidDefSend, type: :rubocop do
  it 'accepts send() calls' do
    expect_no_offenses('send(:a)')
  end

  it 'rejects send() definitions' do
    result = inspect_source('def send(a:); end')

    expect(result.first.cop_name).to eq('Zammad/ForbidDefSend')
  end

  it 'rejects self.send() definitions' do
    result = inspect_source('def self.send(a:); end')

    expect(result.first.cop_name).to eq('Zammad/ForbidDefSend')
  end
end
