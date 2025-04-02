# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/core_workflow_examples'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Groups', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :group, klass: Group, path: 'manage/groups', create_params: { email_address_id: 1 }
  end

  describe 'with nested groups' do
    let(:group1) { create(:group) }
    let(:group2) { create(:group, parent: group1) }
    let(:group3) { create(:group, parent: group2) }

    before do
      group3 # cascade create
      visit '#manage/groups'
    end

    it 'displays complete group path using chevrons' do
      expect(page).to have_text(group3.name.gsub!(%r{::}, ' › '))
    end

    it 'sorts group paths in correct order' do
      expect(page).to have_text("#{group1.fullname}\n#{group2.fullname}\n#{group3.fullname}")
    end

    describe 'when creating a new group' do
      let(:group_name_last) { Faker::Lorem.unique.word.capitalize }

      before do
        click_on 'New Group'
      end

      it 'creates a nested group' do
        fill_in 'Name', with: group_name_last
        set_tree_select_value('parent_id', group3.fullname)

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_on 'Submit'

        expect(Group.last.name).to eq("#{group3.name}::#{Group.last.name_last}")
      end
    end
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

        click_on 'Submit'
      end

      expect(Group.find_by(name: 'Users').assignment_timeout).to eq(30)

      find('td', text: 'Users').click

      in_modal do
        fill_in 'Assignment Timeout', with: ''

        # Needed for chrome, when element is outside viewport.
        scroll_into_view('button.js-submit', position: :bottom)

        click_on 'Submit'
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

      expect(page).to have_select('email_address_id', text: "#{email_address.name} <#{email_address.email}>")
    end
  end
end
