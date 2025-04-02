# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/can_perform_changes_examples'

RSpec.describe 'Organization::PerformChanges' do
  subject(:object) { create(:organization) }

  include_examples 'CanPerformChanges', object_name: 'Organization', data_privacy_deletion_task: false
end
