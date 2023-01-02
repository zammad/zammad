# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/concerns/has_tags_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer, current_user_id: 1, type: :model do
  subject!(:kb_answer) { create(:knowledge_base_answer) }

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

      expect(described_class.sorted_by_published).to match_array [answer3, answer1, answer2]
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

      expect(described_class.sorted_by_internally_published).to match_array [answer4, answer3, answer1, answer2, answer5]
    end
  end
end
