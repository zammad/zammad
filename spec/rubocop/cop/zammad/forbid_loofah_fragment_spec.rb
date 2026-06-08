# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require_relative '../../../../.dev/rubocop/cop/zammad/forbid_loofah_fragment'

RSpec.describe RuboCop::Cop::Zammad::ForbidLoofahFragment, type: :rubocop do

  it 'accepts Loofah.html5_fragment' do
    expect_no_offenses('Loofah.html5_fragment')
  end

  it 'rejects Loofah.fragment' do
    result = inspect_source('Loofah.fragment')
    expect(result.first.cop_name).to eq('Zammad/ForbidLoofahFragment')
  end
end
