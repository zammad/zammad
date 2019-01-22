require 'rails_helper'
require 'models/application_model_examples'

RSpec.describe Ticket::StateType, type: :model do
  include_examples 'ApplicationModel'
end
