# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::RequestCache do
  describe '.fetch' do
    it 'does cache true values' do
      described_class.fetch_value('a') { true }
      value_a = described_class.fetch_value('a') { 'bb' }

      expect(value_a).to be(true)
    end

    it 'does cache false values' do
      described_class.fetch_value('a') { false }
      value_a = described_class.fetch_value('a') { 'bb' }

      expect(value_a).to be(false)
    end
  end

  describe '.clear' do
    it 'does clear after update of an object' do
      described_class.fetch_value('a') { true }

      expect { Ticket.first.touch }
        .to change { described_class.request_cache.key? 'a' }
        .to(false)
    end
  end
end
