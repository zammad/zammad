# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Common::AttributeMapper, sequencer: :unit do

  let(:map) do
    {
      old_key: :new_key,
      second:  :new_second,
    }
  end

  it 'expects an implementation of the .map method' do
    expect do
      described_class.map
    end.to raise_error(RuntimeError)
  end

  it 'declares uses from map keys' do
    allow(described_class).to receive(:map).and_return(map)
    expect(described_class.uses).to eq(map.keys)
  end

  it 'declares provides from map values' do
    allow(described_class).to receive(:map).and_return(map)
    expect(described_class.provides).to eq(map.values)
  end

  it 'maps as configured' do

    old = {
      old_key: :value,
      second:  :second_value,
    }

    allow(described_class).to receive(:map).and_return(map)
    result = process(old)

    expect(result.keys.size).to eq 2
    expect(result[:new_key]).to eq old[:old_key]
    expect(result[:new_second]).to eq old[:second]
  end
end
