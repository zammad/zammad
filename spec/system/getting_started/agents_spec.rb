# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Getting Started > Agents', type: :system do
  let(:group)  { Group.first }
  let(:group2) { Group.second }

  it 'shows email address already used error' do
    visit 'getting_started/agents', skip_waiting: true

    fill_in 'firstname',        with: 'Test'
    fill_in 'lastname',         with: 'Test'
    fill_in 'email',            with: 'admin@example.com'

    click '.btn--success'

    within '.js-danger' do
      expect(page)
        .to have_text("Email address 'admin@example.com' is already used for another user.")
    end
  end

  it 'toggles groups on (un)checking agent role' do
    visit 'getting_started/agents', skip_waiting: true

    expect(page).to have_css('[data-attribute-name="group_ids"]')
    click 'span', text: 'Agent'
    expect(page).to have_no_css('[data-attribute-name="group_ids"]')
    click 'span', text: 'Agent'
    expect(page).to have_css('[data-attribute-name="group_ids"]')
  end

  it 'adds group permissions correctly' do
    visit 'getting_started/agents', skip_waiting: true

    expect(page).to have_no_css '[data-attribute-name="group_ids"] tbody tr[data-id]'

    within '.js-groupListNewItemRow' do
      click '.js-input'
      click 'li', text: group.name
      click 'input[value="full"]', visible: :all
      click '.js-add'
    end

    within '.js-groupListNewItemRow' do
      click '.js-input'
      click 'li', text: group2.name
      click 'input[value="read"]', visible: :all
      click '.js-add'
    end

    within "[data-attribute-name='group_ids'] tbody tr[data-id='#{group.id}']" do
      click '.js-remove'
    end

    fill_in 'email', with: 'test@example.com'

    click '.btn--success'

    expect(User.last.user_groups).to contain_exactly(
      have_attributes(group: group2, access: 'read')
    )
  end
end
