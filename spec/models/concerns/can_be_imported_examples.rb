# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'CanBeImported' do
  describe '.importable?' do
    it 'returns true' do
      expect(described_class.importable?).to be(true)
    end
  end
end
