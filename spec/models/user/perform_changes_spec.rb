# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/can_perform_changes_examples'

RSpec.describe 'User::PerformChanges' do
  subject(:object) { create(:user) }

  include_examples 'CanPerformChanges', object_name: 'User'
end
