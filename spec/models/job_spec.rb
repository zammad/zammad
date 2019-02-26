require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Job, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { selectors: %i[condition perform] }
end
