# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/has_optional_groups_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe AI::TextTool, type: :model do
  it_behaves_like 'ApplicationModel', can_create_update: { unique_name: true }
  it_behaves_like 'HasOptionalGroups', model_factory: :ai_text_tool
  it_behaves_like 'HasXssSanitizedNote', model_factory: :ai_text_tool
end
