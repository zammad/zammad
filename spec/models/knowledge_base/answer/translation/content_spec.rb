# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation::Content, type: :model, current_user_id: 1 do
  subject { create(:knowledge_base_answer_translation_content) }

  include_context 'factory'

  it { is_expected.to have_one(:translation) }
end
