# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Locale, type: :model do
  subject { create(:knowledge_base_locale) }

  include_context 'factory'
end
