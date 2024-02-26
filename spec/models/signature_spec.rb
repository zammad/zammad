# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'
require 'models/application_model/has_cache_examples'

RSpec.describe Signature, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :signature
  it_behaves_like 'HasXssSanitizedNote', model_factory: :signature
  it_behaves_like 'Association clears cache', association: :groups
end
