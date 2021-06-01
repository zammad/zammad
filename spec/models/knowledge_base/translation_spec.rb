# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Translation, type: :model do
  subject { create(:knowledge_base).translations.first }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:knowledge_base_id).with_message(%r{}) }

  it { is_expected.to belong_to(:knowledge_base) }
  it { is_expected.to belong_to(:kb_locale) }
end
