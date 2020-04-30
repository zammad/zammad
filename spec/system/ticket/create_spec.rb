require 'rails_helper'

require 'system/examples/text_modules_examples'

RSpec.describe 'Ticket Create', type: :system do
  context 'when applying ticket templates' do
    let(:agent) { create(:agent_user, groups: [permitted_group]) }
    let(:permitted_group) { create(:group) }
    let(:unpermitted_group) { create(:group) }
    let!(:template) { create(:template, :dummy_data, group: unpermitted_group, owner: agent) }

    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated: -> { agent } do
      visit 'ticket/create'

      use_template(template)
      expect(page).not_to have_selector 'select[name="group_id"]'
    end
  end

  context 'when using text modules' do
    include_examples 'text modules', path: 'ticket/create'
  end
end
