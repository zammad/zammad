require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation::Content, type: :model do
  subject { create(:knowledge_base_answer_translation_content) }

  before { UserInfo.current_user_id = 1 }

  include_context 'factory'

  it { is_expected.to have_one(:translation) }
end
