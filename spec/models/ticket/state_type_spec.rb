require 'rails_helper'
require 'models/application_model_examples'
require 'models/concerns/can_be_imported_examples'

RSpec.describe Ticket::StateType, type: :model do
  it_behaves_like 'ApplicationModel'
  it_behaves_like 'CanBeImported'
end
