# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/concerns/has_tags_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer, current_user_id: 1, type: :model do
  subject(:kb_answer) { create(:knowledge_base_answer) }

  it_behaves_like 'HasTags'

  include_context 'factory'

  it_behaves_like 'ChecksKbClientNotification'

  it { is_expected.not_to validate_presence_of(:category_id) }
  it { is_expected.to belong_to(:category) }
  it { expect(kb_answer.attachments).to be_blank }

  context 'with attachment' do
    subject(:kb_answer) { create(:knowledge_base_answer, :with_attachment) }

    it { expect(kb_answer.attachments).to be_present }
  end

  describe '#assets', current_user_id: -> { user.id } do
    let(:assets)                  { another_category_answer && internal_answer.assets }
    let(:user)                    { create(:agent) }
    let(:another_category)        { create(:knowledge_base_category, knowledge_base: knowledge_base) }
    let(:another_category_answer) { create(:knowledge_base_answer, :internal, category: another_category) }

    include_context 'basic Knowledge Base'

    context 'without permissions' do
      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }
    end

    context 'with readable another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'reader'
      end

      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }
    end

    context 'with hidden another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'none'
      end

      it { expect(assets).to include_assets_of internal_answer }
      it { expect(assets).to include_assets_of category }

      context 'with published answer' do
        let(:another_category_published_answer) { create(:knowledge_base_answer, :published, category: another_category) }

        before { another_category_published_answer }

        it { expect(assets).to include_assets_of internal_answer }
        it { expect(assets).to include_assets_of category }
      end
    end
  end

  describe '#sorted_by_published' do
    it 'sorts by publishing or update date, whichever is greater' do
      described_class.destroy_all

      answer1 = create(:knowledge_base_answer, published_at: 1.day.ago)
      answer1.update! updated_at: 1.day.ago
      answer2 = create(:knowledge_base_answer, published_at: 1.day.ago)
      answer2.update! updated_at: 1.hour.ago
      answer3 = create(:knowledge_base_answer, published_at: 1.minute.ago)
      answer3.update! updated_at: 1.day.ago

      expect(described_class.sorted_by_published).to contain_exactly(answer3, answer1, answer2)
    end
  end

  describe '#sorted_by_internally_published' do
    it 'sorts by internally publishing or update date, whichever is greater' do
      described_class.destroy_all

      answer1 = create(:knowledge_base_answer, internal_at: 2.days.ago, published_at: 1.day.ago)
      answer1.update! updated_at: 2.days.ago
      answer2 = create(:knowledge_base_answer, published_at: 1.day.ago)
      answer2.update! updated_at: 1.hour.ago
      answer3 = create(:knowledge_base_answer, published_at: 30.minutes.ago)
      answer3.update! updated_at: 1.day.ago
      answer4 = create(:knowledge_base_answer, internal_at: 1.minute.ago)
      answer4.update! updated_at: 1.day.ago
      answer5 = create(:knowledge_base_answer, published_at: 1.week.ago, internal_at: nil)
      answer5.update! updated_at: 1.week.ago
      _answer6 = create(:knowledge_base_answer, internal_at: nil, published_at: nil)

      expect(described_class.sorted_by_internally_published).to contain_exactly(answer4, answer3, answer1, answer2, answer5)
    end
  end

  describe '.visible_by_categories' do
    include_context 'basic Knowledge Base'
    let(:struct) { KnowledgeBase::AccessibleCategories::CategoriesStruct.new }

    before do
      published_answer
      internal_answer
      draft_answer
      published_answer_in_other_category
      internal_answer_in_other_category
    end

    it 'returns any article in editor categories' do
      struct.editor = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer, internal_answer, draft_answer)
    end

    it 'returns internal and published answers in reader categories' do
      struct.reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer, internal_answer)
    end

    it 'returns only public answers in public reader categories' do
      struct.public_reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(published_answer)
    end

    it 'returns correct answers with a combination of categories' do
      struct.editor = [other_category]
      struct.reader = [category]

      expect(described_class.visible_by_categories(struct))
        .to contain_exactly(
          published_answer, internal_answer, published_answer_in_other_category, internal_answer_in_other_category
        )
    end
  end

  describe 'visible_to_user' do
    include_context 'basic Knowledge Base'

    before do
      published_answer
      internal_answer
      draft_answer
      internal_answer_in_other_category
      draft_answer_in_other_category
    end

    context 'when granular permissions enabled' do
      before do
        next if !defined?(access)

        KnowledgeBase::PermissionsUpdate
          .new(category)
          .update! user.roles.first => access
      end

      context 'when user is editor' do
        let(:user) { create(:admin_only) }

        context 'when user has specified editor access to one category' do
          let(:access) { 'editor' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer, draft_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end

        context 'when user has specified reader access to one category' do
          let(:access) { 'reader' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end

        context 'when user has specified no access to one category' do
          let(:access) { 'none' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer,
              internal_answer_in_other_category, draft_answer_in_other_category
            )
          end
        end
      end

      context 'when user is reader' do
        let(:user) { create(:agent) }

        context 'when user has specified reader access to one category' do
          let(:access) { 'reader' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer, internal_answer_in_other_category
            )
          end
        end

        context 'when user has specified no access to one category' do
          let(:access) { 'none' }

          it 'returns accessible answers' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer, internal_answer_in_other_category
            )
          end
        end
      end

      context 'when user is a guest' do
        let(:user) { create(:customer) }

        context 'when user has public access' do
          it 'returns published answers for public reader' do
            expect(described_class.visible_to_user(user)).to contain_exactly(
              published_answer
            )
          end

          it 'does not call visible_by_categories' do
            allow(described_class).to receive(:visible_by_categories)

            described_class.visible_to_user(user)

            expect(described_class).not_to have_received(:visible_by_categories)
          end
        end
      end
    end

    context 'when granular permissions not enabled' do
      context 'when user is editor' do
        let(:user) { create(:admin) }

        it 'returns all answers for editor' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer, internal_answer, draft_answer,
            internal_answer_in_other_category, draft_answer_in_other_category
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user is reader' do
        let(:user) { create(:agent) }

        it 'returns internal answers for reader' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer, internal_answer,
            internal_answer_in_other_category
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user is public reader' do
        let(:user) { create(:customer) }

        it 'returns published answers for public reader' do
          expect(described_class.visible_to_user(user)).to contain_exactly(
            published_answer
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(user)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end

      context 'when user not given' do
        it 'returns published answers for public reader' do
          expect(described_class.visible_to_user(nil)).to contain_exactly(
            published_answer
          )
        end

        it 'does not call visible_by_categories' do
          allow(described_class).to receive(:visible_by_categories)

          described_class.visible_to_user(nil)

          expect(described_class).not_to have_received(:visible_by_categories)
        end
      end
    end
  end
end
