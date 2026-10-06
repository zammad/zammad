# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MicrosoftCloud, :aggregate_failures do
  it 'defaults omitted and empty values to Global' do
    expect(described_class.new.name).to eq('global')
    expect(described_class.new('').name).to eq('global')
  end

  it 'rejects arbitrary endpoint values' do
    expect { described_class.new('https://example.com') }.to raise_error(ArgumentError, 'Unknown Microsoft cloud.')
  end
end
