# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/concerns/has_tags_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer, type: :model, current_user_id: 1 do
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
end
