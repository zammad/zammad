require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Answer::Translation, type: :model, current_user_id: 1 do
  subject { create(:knowledge_base_answer_translation) }

  include_context 'factory'

  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_uniqueness_of(:kb_locale_id).scoped_to(:answer_id).with_message(//) }

  it { is_expected.to belong_to(:answer) }
  it { is_expected.to belong_to(:kb_locale) }
end
