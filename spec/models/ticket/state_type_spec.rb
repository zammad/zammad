require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Ticket::StateType, type: :model do
  it_behaves_like 'ApplicationModel'
end
