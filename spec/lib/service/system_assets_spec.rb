# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::SystemAssets do
  describe '.backend' do
    it 'returns class when identifier is correct' do
      expect(described_class.backend('product_logo'))
        .to eq described_class::ProductLogo
    end

    it 'returns nil when identifier is not correct' do
      expect(described_class.backend('example')).to be_nil
    end
  end
end
