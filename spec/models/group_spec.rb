require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'
require 'models/concerns/has_object_manager_attributes_validation_examples'

RSpec.describe Group, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
  it_behaves_like 'HasObjectManagerAttributesValidation'
end
