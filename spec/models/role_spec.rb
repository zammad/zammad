require 'rails_helper'
require 'models/concerns/has_groups_examples'

RSpec.describe Role do
  include_examples 'HasGroups'
end
