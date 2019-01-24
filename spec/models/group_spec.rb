require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Group, type: :model do
  it_behaves_like 'ApplicationModel'
end
