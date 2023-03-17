# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Cache do
  describe '.get' do
    before do
      allow(ActiveSupport::Deprecation).to receive(:warn)
    end

    it 'alias of Rails.cache.read' do
      allow(Rails.cache).to receive(:read)

      described_class.read('foo')

      expect(Rails.cache).to have_received(:read).with('foo')
    end

    it 'throws deprecation warning' do
      described_class.read('foo')

      expect(ActiveSupport::Deprecation).to have_received(:warn)
    end
  end
end
