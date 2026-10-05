# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'
require 'models/knowledge_base/plain_title_index_examples'

RSpec.describe KnowledgeBase::Translation, type: :model do
  subject { create(:knowledge_base).translations.first }

  include_context 'factory'

  it_behaves_like 'indexing the plain title'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:knowledge_base_id).with_message(%r{}) }

  it { is_expected.to belong_to(:knowledge_base) }
  it { is_expected.to belong_to(:kb_locale) }
end
