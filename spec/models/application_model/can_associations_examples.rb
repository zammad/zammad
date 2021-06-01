# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanAssociations' do
  subject { create(described_class.name.underscore) }

  describe '#attributes_with_association_ids (for supplying model data to front-end framework)' do
    describe 'caching' do
      let(:cache_key) { "#{described_class}::aws::#{subject.id}" }

      context 'with empty cache' do
        it 'stores the computed value in the cache' do
          expect { subject.attributes_with_association_ids }
            .to change { Rails.cache.read(cache_key) }
        end
      end

      context 'with stored value in cache' do
        before { Rails.cache.write(cache_key, { foo: 'bar' }) }

        it 'returns the cached value' do
          expect(subject.attributes_with_association_ids).to include(foo: 'bar')
        end

        it 'does not modify the cached value' do
          expect { subject.attributes_with_association_ids }
            .not_to change { Rails.cache.read(cache_key) }
        end
      end
    end
  end
end
