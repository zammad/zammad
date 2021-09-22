# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Groups', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :group, klass: Group, path: 'manage/groups'
  end

  describe 'Core Workflow' do
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

  context "Issue 2544 - Can't remove auto assignment timeout" do
    before do
      visit '/#manage/groups'
    end

    it 'is possible to reset the assignment timeout of a group' do
      find('td', text: 'Users').click

      within '.modal-dialog' do
        fill_in 'Assignment Timeout', with: '30'

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_button
      end

      expect(Group.find_by(name: 'Users').assignment_timeout).to eq(30)

      find('td', text: 'Users').click

      within '.modal-dialog' do
        fill_in 'Assignment Timeout', with: ''

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_button
      end
      expect(Group.find_by(name: 'Users').assignment_timeout).to be nil
    end
  end
end
