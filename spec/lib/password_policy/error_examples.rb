# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'declaring an error' do
  describe '#error' do
    let(:instance) { described_class.new('') }

    it 'returns an Array' do
      expect(instance.error).to be_a(Array)
    end

    it 'is contains at least one value' do
      expect(instance.error).to be_present
    end
  end
end
