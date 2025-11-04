# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'provider/ping!' do
  describe '.ping!' do
    before do
      allow(HttpLog).to receive(:create)
      described_class.ping!(Setting.get('ai_provider_config'))
    end

    it 'does not raise and does not write to the log' do
      expect(HttpLog).not_to have_received(:create)
    end
  end
end
