require 'rails_helper'

require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create', type: :system do
  context 'when applying ticket templates' do
    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated: false do
      user              = create(:agent_user)
      permitted_group   = create(:group)
      unpermitted_group = create(:group)

      user.group_names_access_map = {
        permitted_group.name => 'full',
      }

      template = create :template, options: {
        'title'    => 'Template Title',
        'group_id' => unpermitted_group.id,
        'owner_id' => '2',
      }

      login(
        username: user.email,
        password: 'test',
      )
      visit 'ticket/create'

      # apply the ticket template and confirm that the group_id dropdown does not appear
      find('#form-template select[name="id"]').find(:option, template.name).select_option
      click '.sidebar-content .js-apply'
      expect(page).not_to have_selector 'select[name="group_id"]'
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end
end
