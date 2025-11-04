# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::AccessibleCategories do
  subject(:instance) { described_class.new(user, categories_filter:) }

  let(:user)              { create(:admin_only) }
  let(:categories_filter) { nil }

  include_context 'basic Knowledge Base'

  describe '#calculate' do
    before do
      published_answer
      published_answer_in_subcategory
      published_answer_in_other_category
    end

    context 'without filter' do
      it 'returns all categories' do
        expect(instance.calculate.visible).to contain_exactly(category, subcategory, other_category)
      end
    end

    context 'with filter' do
      let(:categories_filter) { category }

      it 'returns selected categories' do
        expect(instance.calculate.visible).to contain_exactly(category, subcategory)
      end
    end
  end

  describe '#taxonomize_category' do
    before do
      KnowledgeBase::PermissionsUpdate.new(category).update! user.roles.first => access
    end

    let(:struct) { described_class::CategoriesStruct.new }

    context 'when group access is editor' do
      let(:access) { 'editor' }

      it 'adds group to editor' do
        instance.send(:taxonomize_category, struct, category)

        expect(struct).to have_attributes(
          editor:        contain_exactly(category),
          reader:        be_blank,
          public_reader: be_blank
        )
      end
    end

    context 'when group access is reader' do
      let(:access) { 'reader' }

      context 'when group has internal content' do
        before do
          internal_answer
        end

        it 'adds group to reader' do
          instance.send(:taxonomize_category, struct, category)

          expect(struct).to have_attributes(
            editor:        be_blank,
            reader:        contain_exactly(category),
            public_reader: be_blank
          )

        end
      end

      context 'when group does not have internal content' do
        before do
          draft_answer
        end

        it 'skips group' do
          instance.send(:taxonomize_category, struct, category)

          expect(struct).to have_attributes(
            editor:        be_blank,
            reader:        be_blank,
            public_reader: be_blank
          )
        end
      end
    end

    context 'when group access is none' do
      let(:access) { 'none' }

      context 'when group has public content' do
        before do
          published_answer
        end

        it 'skips group' do
          instance.send(:taxonomize_category, struct, category)

          expect(struct).to have_attributes(
            editor:        be_blank,
            reader:        be_blank,
            public_reader: contain_exactly(category)
          )
        end
      end

      context 'when group does not have public content' do
        before do
          internal_answer
        end

        it 'skips group' do
          instance.send(:taxonomize_category, struct, category)

          expect(struct).to have_attributes(
            editor:        be_blank,
            reader:        be_blank,
            public_reader: be_blank
          )
        end
      end
    end
  end

  describe '.for_user' do
    it 'calls #calculate once due to caching' do
      count = 0
      allow_any_instance_of(described_class).to receive(:calculate) { count += 1 }

      3.times { described_class.for_user(user) }

      expect(count).to eq 1
    end

    it 'calls calculate multiple items with different filters' do
      count = 0
      allow_any_instance_of(described_class).to receive(:calculate) { count += 1 }

      described_class.for_user(user)
      described_class.for_user(user, categories_filter: [category])

      expect(count).to eq 2
    end

    it 'passes user and categories to cache key' do
      allow(described_class).to receive(:cache_key).and_call_original

      described_class.for_user(user, categories_filter: [category])

      expect(described_class).to have_received(:cache_key).with(user, categories_filter: [category])
    end
  end

  describe '.cache_key' do
    it 'uses same cache key for matching user roles' do
      user1 = create(:agent)
      user2 = create(:agent)

      key1 = described_class.cache_key(user1)
      key2 = described_class.cache_key(user2)

      expect(key1).to eq key2
    end

    it 'uses different cache key for interesecting roles' do
      user1 = create(:admin)
      user2 = create(:agent)

      key1 = described_class.cache_key(user1)
      key2 = described_class.cache_key(user2)

      expect(key1).not_to eq key2
    end

    it 'adds categories to cache key' do
      user = create(:admin)

      category && subcategory

      key1 = described_class.cache_key(user, categories_filter: [category])
      key2 = described_class.cache_key(user, categories_filter: [subcategory])

      expect(key1).not_to eq key2
    end

    it 'bumps cache key on answer creation' do
      user = create(:admin)

      expect { create(:knowledge_base_answer, category: category) }
        .to change { described_class.cache_key(user) }
    end

    it 'bumps cache key on answer publishing' do
      user = create(:admin)
      draft_answer
      expect { draft_answer.can_be_published_aasm.aasm.fire! :publish, user }
        .to change { described_class.cache_key(user) }
    end

    it 'bumps cache key on answer destroying' do
      user = create(:admin)
      published_answer

      expect { published_answer.destroy }.to change { described_class.cache_key(user) }
    end

    it 'bumps cache key on category creation' do
      user = create(:admin)

      expect { other_category }
        .to change { described_class.cache_key(user) }
    end

    it 'bumps cache key on adding granular permissions' do
      user = create(:admin)

      expect { category.permissions.create!(role: user.roles.first, access: 'reader') }
        .to change { described_class.cache_key(user) }
    end
  end
end
