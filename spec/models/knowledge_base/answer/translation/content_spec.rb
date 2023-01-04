# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation::Content, current_user_id: 1, type: :model do
  subject { create(:knowledge_base_answer_translation_content) }

  include_context 'factory'

  it { is_expected.to have_one(:translation) }
end
