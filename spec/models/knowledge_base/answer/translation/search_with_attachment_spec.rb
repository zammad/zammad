# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, current_user_id: -> { user.id }, searchindex: 1, type: :model do
  # include_context 'basic Knowledge Base'

  let(:user)   { create(:admin) }
  let(:query)  { 'RTF document' }
  let(:answer) { create(:knowledge_base_answer, :published, :with_attachment, attachment_filename: 'test.rtf') }

  context 'search with attachment' do
    before do
      answer

      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, described_class])
    end

    it do
      expect(described_class.search(query: query, current_user: user))
        .to include answer.translations.first
    end

    # https://github.com/zammad/zammad/issues/4134
    # https://github.com/zammad/zammad/issues/5889
    context 'when associations are updated' do
      it 'does not delete the attachment from the search index' do
        user.update!(firstname: 'some name here')
        user.search_index_update_associations
        SearchIndexBackend.refresh

        expect(described_class.search(query: query, current_user: user))
          .to include answer.translations.first
      end
    end
  end
end
