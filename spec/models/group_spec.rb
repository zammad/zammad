# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'
require 'models/concerns/has_collection_update_examples'
require 'models/concerns/has_ticket_create_screen_impact_examples'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Group, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributesValidation'
  it_behaves_like 'HasCollectionUpdate', collection_factory: :group
  it_behaves_like 'HasTicketCreateScreenImpact', create_screen_factory: :group
  it_behaves_like 'HasXssSanitizedNote', model_factory: :group
end
