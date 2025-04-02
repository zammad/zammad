# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Locale, type: :model do
  subject { create(:knowledge_base_locale) }

  include_context 'factory'

  describe 'destroying' do
    include_context 'basic Knowledge Base'

    it 'destroys locale' do
      published_answer # populate locale

      expect { primary_locale.destroy! }
        .not_to raise_error
    end
  end
end
