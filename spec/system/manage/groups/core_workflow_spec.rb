# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'

RSpec.describe 'Manage > Groups > Core Workflow', type: :system do
  include_examples 'core workflow' do
    let(:object_name) { 'Group' }
    let(:before_it) do
      lambda {
        ensure_websocket(check_if_pinged: false) do
          visit 'manage/groups'
          click_on 'New Group'
        end
      }
    end
  end
end
