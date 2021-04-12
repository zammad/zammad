require 'rails_helper'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Macro, type: :model do
  it_behaves_like 'HasCollectionUpdate', collection_factory: :macro
  it_behaves_like 'HasXssSanitizedNote', model_factory: :macro
end
