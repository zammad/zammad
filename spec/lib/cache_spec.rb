# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Cache do
  describe '.get' do
    before { allow(Rails.cache).to receive(:read) }

    it 'alias of Rails.cache.read' do
      described_class.read('foo')

      expect(Rails.cache).to have_received(:read).with('foo')
    end
  end
end
