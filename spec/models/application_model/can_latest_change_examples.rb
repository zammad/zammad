# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'ApplicationModel::CanLatestChange' do
  subject { create(described_class.name.underscore) }

  describe '#latest_change' do
    describe 'caching updated_at' do
      context 'with empty cache' do
        it 'stores updated_at in the cache and returns it' do
          expect(subject.updated_at).to eq(described_class.latest_change)
        end
      end

      context 'with valid cache' do
        before { described_class.latest_change_set(subject.updated_at) }

        it 'return updated_at from cache' do
          expect(subject.updated_at).to eq(described_class.latest_change)
        end
      end

      context 'delete valid cache' do
        before do
          subject.touch
          described_class.latest_change_set(nil)
        end

        it 'stores new updated_at in the cache and returns it' do
          expect(subject.updated_at).to eq(described_class.latest_change)
        end
      end
    end
  end
end
