require 'rails_helper'
require 'models/concerns/has_groups_examples'

RSpec.describe Role do
  let(:group_access_instance) { create(:role) }
  let(:new_group_access_instance) { build(:role) }

  include_examples 'HasGroups'
end
