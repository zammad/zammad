# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Role', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :role, klass: Role, path: 'manage/roles'
  end

  # https://github.com/zammad/zammad/issues/4100
  context 'creating a new role' do
    let(:group)  { Group.first }
    let(:group2) { Group.second }

    before do
      visit '#manage/roles'

      within(:active_content) do
        find('[data-type=new]').click
      end
    end

    it 'handles permission checkboxes correctly' do
      in_modal do
        scroll_into_view 'input[data-permission-name="ticket.agent"]'
        click 'input[data-permission-name="ticket.agent"]', visible: :all
        scroll_into_view '[data-attribute-name="group_ids"]'

        within '.js-groupListNewItemRow' do
          click '.js-input'
          click 'li', text: group.name

          click 'input[value="full"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).to be_checked

          click 'input[value="read"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).not_to be_checked
          expect(find('input[value="read"]', visible: :all)).to be_checked

          click 'input[value="full"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).to be_checked
          expect(find('input[value="read"]', visible: :all)).not_to be_checked
        end
      end
    end
  end

  context 'updating an existing role' do
    let(:role)   { create(:role, :agent) }
    let(:row)    { find "table tbody tr[data-id='#{role.id}']" }
    let(:group)  { Group.first }
    let(:group2) { Group.second }

    before do
      role

      visit '#manage/roles'

      within(:active_content) do
        row.click
      end
    end

    it 'adds group permissions correctly' do
      in_modal do
        scroll_into_view '[data-attribute-name="group_ids"]'

        expect(page).to have_no_css 'table.settings-list tbody tr[data-id]'

        within '.js-groupListNewItemRow' do
          click '.js-input'
          click 'li', text: group.name
          click 'input[value="full"]', visible: :all

          click '.js-add'
        end

        expect(page).to have_css "table.settings-list tbody tr[data-id='#{group.id}']"

        within '.js-groupListNewItemRow' do
          click '.js-input'
          click 'li', text: group2.name

          click 'input[value="read"]', visible: :all
        end

        click_on 'Submit'
      end

      # only the first group is added
      # because add button is not clicked for the 2nd group
      expect(role.reload.role_groups).to contain_exactly(
        have_attributes(group: group, access: 'full')
      )
    end

    context 'when role already has a group configured', authenticated_as: :authenticate do
      def authenticate
        role.groups << group
        role.groups << group2
        true
      end

      it 'toggles groups on (un)checking agent group' do
        in_modal do
          scroll_into_view '[data-attribute-name="group_ids"]'

          expect(page).to have_css('[data-attribute-name="group_ids"]')
          click 'span', text: 'Agent tickets'
          expect(page).to have_no_css('[data-attribute-name="group_ids"]')
          click 'span', text: 'Agent tickets'
          expect(page).to have_css('[data-attribute-name="group_ids"]')
        end
      end

      it 'removes group correctly' do
        in_modal do
          scroll_into_view 'table.settings-list'

          within "table.settings-list tbody tr[data-id='#{group.id}']" do
            click '.js-remove'
          end

          click_on 'Submit'
        end

        expect(role.reload.role_groups).to contain_exactly(
          have_attributes(group: group2, access: 'full')
        )
      end
    end
  end
end
