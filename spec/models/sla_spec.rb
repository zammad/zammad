require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Sla, type: :model do
  it_behaves_like 'ApplicationModel', can_assets: { associations: :calendar, selectors: :condition }
end
