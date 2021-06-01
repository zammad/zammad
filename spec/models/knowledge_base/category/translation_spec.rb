# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Category::Translation, type: :model do
  subject { create(:knowledge_base_category_translation) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:category_id).with_message(%r{}) }

  it { is_expected.to belong_to(:category) }
  it { is_expected.to belong_to(:kb_locale) }
end
