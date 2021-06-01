# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'CanBeImported' do
  describe '.importable?' do
    it 'returns true' do
      expect(described_class.importable?).to be(true)
    end
  end
end
