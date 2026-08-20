# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::IconCatalog do
  before { described_class.reset! }

  after { described_class.reset! }

  describe '.for' do
    it 'returns a catalog for a known iconset' do
      expect(described_class.for('FontAwesome')).to have_attributes(icon_set: 'FontAwesome')
    end

    it 'raises for an unknown iconset' do
      expect { described_class.for('../../../etc/passwd') }.to raise_error(ArgumentError, %r{Unknown knowledge base iconset})
    end

    it 'memoizes the catalog per iconset' do
      catalog = described_class.for('anticon')

      expect(described_class.for('anticon')).to be(catalog)
    end

    it 'keeps catalogs of different iconsets apart' do
      expect(described_class.for('anticon')).not_to be(described_class.for('material'))
    end

    it 'parses the catalog file only once' do
      allow(JSON).to receive(:parse).and_call_original

      2.times { described_class.for('anticon').search('forward') }

      expect(JSON).to have_received(:parse).once
    end
  end

  describe '#icons' do
    KnowledgeBase::ICONSETS.each do |icon_set|
      context "with iconset #{icon_set}" do
        let(:icons) { described_class.for(icon_set).icons }

        it 'loads icons with a codepoint and a name' do
          expect(icons).to be_present.and(all(have_attributes(unicode: be_present, name: be_present)))
        end
      end
    end
  end

  describe '#search' do
    subject(:result) { described_class.for(icon_set).search(query, limit: limit) }

    let(:icon_set) { 'FontAwesome' }
    let(:limit)    { nil }

    context 'when matching the name' do
      let(:query) { 'glass' }

      it 'finds the icon' do
        expect(result).to include(have_attributes(unicode: 'f000', name: 'glass'))
      end

      it 'matches case-insensitively' do
        expect(described_class.for(icon_set).search('GLASS')).to eq(result)
      end
    end

    context 'when matching a filter keyword' do
      let(:query) { 'martini' }

      it 'finds the icon, even though its name does not contain the query' do
        expect(result).to include(have_attributes(name: 'glass'))
      end
    end

    context 'when matching the codepoint' do
      let(:query) { 'f000' }

      it 'finds the icon, so a stored value can be resolved to its name' do
        expect(result).to include(have_attributes(name: 'glass'))
      end
    end

    context 'when the query uses whitespace instead of delimiters' do
      let(:icon_set) { 'material' }
      let(:query)    { '3d rotation' }

      it 'finds the underscore-delimited icon' do
        expect(result).to include(have_attributes(name: '3d_rotation'))
      end
    end

    context 'when the query uses whitespace instead of a dash' do
      let(:icon_set) { 'Simple-Line-Icons' }
      let(:query)    { 'user female' }

      it 'finds the dash-delimited icon' do
        expect(result).to include(have_attributes(name: 'user-female'))
      end
    end

    context 'when the query terms are in another order than the icon name' do
      let(:icon_set) { 'ionicons' }
      let(:query)    { 'wifi android' }

      it 'finds the icon' do
        expect(result).to include(have_attributes(name: 'ion-android-wifi'))
      end
    end

    context 'when the query terms are spread over the icon name' do
      let(:query) { 'folder outlined' }

      it 'finds every icon carrying all of them' do
        expect(result).to include(
          have_attributes(name: 'folder outlined'),
          have_attributes(name: 'folder open outlined'),
        )
      end
    end

    context 'when the query terms are spread over name and keywords' do
      let(:query) { 'glass martini' }

      it 'finds the icon' do
        expect(result).to include(have_attributes(name: 'glass'))
      end
    end

    context 'when only one of the query terms matches' do
      let(:query) { 'folder nonexistingiconname' }

      it 'returns no icons' do
        expect(result).to be_empty
      end
    end

    context 'when matching the alias' do
      let(:icon_set) { 'Simple-Line-Icons' }
      let(:query)    { 'user-female' }

      it 'finds the icon by its id' do
        expect(result).to include(have_attributes(name: 'user-female'))
      end
    end

    context 'when nothing matches' do
      let(:query) { 'nonexistingiconname' }

      it 'returns no icons' do
        expect(result).to be_empty
      end
    end

    context 'when a codepoint is listed under several alias names' do
      let(:icon_set) { 'anticon' }
      let(:query)    { 'e608' }

      it 'returns it only once, labeled with the first name' do
        expect(result).to contain_exactly(have_attributes(unicode: 'e608', name: 'right-circle'))
      end

      it 'keeps the alias names searchable' do
        expect(described_class.for(icon_set).search('caret circle right')).to include(have_attributes(unicode: 'e608'))
      end
    end

    context 'without a limit' do
      let(:query) { 'user' }

      it 'returns at most the default limit' do
        expect(result.length).to be <= described_class::DEFAULT_LIMIT
      end
    end

    context 'with a limit' do
      let(:query) { 'user' }
      let(:limit) { 2 }

      it 'respects the limit' do
        expect(result.length).to eq(2)
      end
    end

    context 'with a negative limit' do
      let(:query) { 'user' }
      let(:limit) { -1 }

      it 'returns no icons instead of raising' do
        expect(result).to be_empty
      end
    end

    context 'with the wildcard query' do
      let(:query) { '*' }
      let(:limit) { 2 }

      it 'returns the complete iconset, ignoring the limit' do
        expect(result).to eq(described_class.for(icon_set).icons)
      end
    end

    context 'when the query is wrapped in asterisks' do
      let(:query) { '*glass*' }

      it 'searches for the enclosed term' do
        expect(result).to include(have_attributes(name: 'glass'))
      end
    end

    context 'with a blank query' do
      let(:query) { '   ' }
      let(:limit) { 2 }

      it 'returns the complete iconset, ignoring the limit' do
        expect(result).to eq(described_class.for(icon_set).icons)
      end
    end
  end
end
