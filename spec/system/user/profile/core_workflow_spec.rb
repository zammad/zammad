# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'

RSpec.describe 'User Profile > Core Workflow', type: :system do
  let(:customer) { create(:customer) }

  include_examples 'core workflow' do
    let(:object_name) { 'User' }
    let(:before_it) do
      lambda {
        ensure_websocket(check_if_pinged: false) do
          visit "#user/profile/#{customer.id}"
          within(:active_content) do
            page.find('.profile .js-action').click
            page.find('.profile li[data-type=edit]').click
          end
        end
      }
    end
  end
end
