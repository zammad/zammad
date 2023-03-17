# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Groups', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :group, klass: Group, path: 'manage/groups'
  end

  # Fixes GitHub Issue#3129 - Deactivation of signature does not clear it from groups
  describe 'When active status of signature assigned to a group is changed', authenticated_as: -> { user } do
    let(:user)      { create(:admin, groups: [group]) }
    let(:group)     { create(:group, signature_id: signature.id) }
    let(:signature) { create(:signature) }

    it 'does not display warning, when signature is active' do
      visit '#manage/groups'

      click "tr[data-id='#{group.id}']"

      expect(page).to have_select('signature_id', selected: signature.name)
        .and have_no_css('.alert--warning')
    end

    context 'When signature is marked inactive' do
      let(:signature) { create(:signature, active: false) }

      it 'displays warning' do
        visit '#manage/groups'

        click "tr[data-id='#{group.id}']"

        expect(page).to have_select('signature_id', selected: signature.name)
          .and have_css('.alert--warning')
      end
    end
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

      in_modal do
        fill_in 'Assignment Timeout', with: '30'

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_button
      end

      expect(Group.find_by(name: 'Users').assignment_timeout).to eq(30)

      find('td', text: 'Users').click

      in_modal do
        fill_in 'Assignment Timeout', with: ''

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_button
      end
      expect(Group.find_by(name: 'Users').assignment_timeout).to be_nil
    end
  end

  context 'Issue 4129 - Tooltips are not displayed correctly' do
    before do
      visit '/#manage/groups'
    end

    it 'renders tooltips correctly' do
      find('td', text: 'Users').click

      in_modal do
        find('div.select[data-attribute-name="follow_up_possible"] .js-helpMessage').hover

        expect(page).to have_css('div.tooltip')
      end
    end
  end

  describe 'Issue #4475 - Group edit dialog shows ??? in email select box', authenticated_as: -> { user } do
    let(:user)          { create(:admin, groups: [group]) }
    let(:email_address) { create(:email_address) }
    let(:group)         { create(:group, email_address: email_address) }

    it 'shows correct email address display name' do
      visit '#manage/groups'

      click "tr[data-id='#{group.id}']"

      expect(page).to have_select('email_address_id', text: "#{email_address.realname} <#{email_address.email}>")
    end
  end
end
