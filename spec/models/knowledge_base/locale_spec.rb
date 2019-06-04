require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Locale, type: :model do
  subject { create(:knowledge_base_locale) }

  include_context 'factory'
end
