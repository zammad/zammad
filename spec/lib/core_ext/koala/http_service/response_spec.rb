# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Koala::HTTPService::Response do
  describe '#data' do
    it 'parses a JSON object' do
      expect(described_class.new(200, '{"id":"1"}', {}).data).to eq('id' => '1')
    end

    it 'parses a raw boolean' do
      expect(described_class.new(200, 'true', {}).data).to be(true)
    end

    it 'returns nil for an empty body' do
      expect(described_class.new(200, '', {}).data).to be_nil
    end
  end
end
