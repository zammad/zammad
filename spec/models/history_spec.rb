require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'

RSpec.describe History, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { own_attributes: false }
  it_behaves_like 'CanBeImported'
end
