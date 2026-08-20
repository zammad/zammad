# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::CategoryContent do
  include_context 'basic Knowledge Base'

  let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

  let(:details) do
    described_class
      .with_current_user(reader)
      .execute(knowledge_base:, category:, locale: primary_locale)
      .dig(:category_details, category.id)
  end

  # Deletability is the one detail that must not follow the current user's view of the tree:
  #   `destroy!` is refused by any answer below the category, including the ones this user may
  #   not see. A draft answer is exactly that case for a reader — it is not counted in
  #   `direct_answer_count`, yet it still blocks the delete.
  context 'with an answer the current user cannot see' do
    before { draft_answer }

    it 'reports the category as not deletable', :aggregate_failures do
      expect(details).to include(deletable: false)
      expect(details).to include(direct_answer_count: 0)
    end
  end

  context 'without any content' do
    it 'reports the category as deletable' do
      expect(details).to include(deletable: true)
    end
  end

  context 'with a subcategory' do
    before { subcategory }

    it 'reports the category as not deletable' do
      expect(details).to include(deletable: false)
    end
  end
end
