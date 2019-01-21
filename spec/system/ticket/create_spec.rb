require 'rails_helper'

RSpec.describe 'Ticket Create', type: :system do
  context 'when applying ticket templates' do
    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    scenario 'unavailable attributes do not get applied', authenticated: false do
      # create a new agent with permissions for only group "some group1"
      user = create :agent_user
      user.group_names_access_map = {
        'some group1' => 'full',
      }

      # create a template that sets the group to Users and ticket owner to user id 1
      template = create :template, options: {
        'title'    => 'Template Title',
        'group_id' => '1',
        'owner_id' => '2',
      }

      # apply the ticket template and confirm that the group_id dropdown does not appear
      login(
        username: user.email,
        password: 'test',
      )
      visit 'ticket/create'
      find('#form-template select[name="id"]').find(:option, template.name).select_option
      click '.sidebar-content .js-apply'
      expect(page).not_to have_selector 'select[name="group_id"]'
    end
  end
end
