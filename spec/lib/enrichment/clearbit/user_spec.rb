# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Enrichment::Clearbit::User do
  describe '.all' do
    let!(:customer)  { create(:customer) }
    let(:enrichment) { instance_double(described_class, synced?: true) }

    before { allow(described_class).to receive(:new).and_return(enrichment) }

    it 'syncs every signup-role user via the top-level User model' do
      described_class.all

      expect(described_class).to have_received(:new).with(customer)
    end
  end
end
