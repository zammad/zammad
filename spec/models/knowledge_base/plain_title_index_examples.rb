# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'indexing the plain title' do
  describe '#search_index_attribute_lookup' do
    it 'indexes the plain title' do
      subject.update!(title: '<b>Bold</b> & topic')

      expect(subject.search_index_attribute_lookup['title']).to eq('Bold & topic')
    end
  end
end
