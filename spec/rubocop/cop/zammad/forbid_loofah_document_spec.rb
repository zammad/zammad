# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

require_relative '../../../../.dev/rubocop/cop/zammad/forbid_loofah_document'

RSpec.describe RuboCop::Cop::Zammad::ForbidLoofahDocument, type: :rubocop do

  it 'accepts Loofah.html5_document' do
    expect_no_offenses('Loofah.html5_document')
  end

  it 'rejects Loofah.document' do
    result = inspect_source('Loofah.document')
    expect(result.first.cop_name).to eq('Zammad/ForbidLoofahDocument')
  end
end
