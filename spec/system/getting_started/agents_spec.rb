# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Getting Started > Agents', type: :system do
  let(:group)  { Group.first }
  let(:group2) { Group.second }

  before do
    visit 'getting_started/agents', skip_waiting: true
  end

  it 'shows email address already used error' do
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
    expect(page).to have_css('[data-attribute-name="group_ids"]')
    click 'span', text: 'Agent'
    expect(page).to have_no_css('[data-attribute-name="group_ids"]')
    click 'span', text: 'Agent'
    expect(page).to have_css('[data-attribute-name="group_ids"]')
  end

  context 'when email is filled in' do
    before do
      fill_in 'email', with: 'test@example.com'
    end

    it 'adds roles correctly' do
      click 'span', text: 'Admin'
      click 'span', text: 'Agent' # unselect preselected role

      click '.btn--success'

      expect(User.last).to have_attributes(
        email: 'test@example.com',
        roles: contain_exactly(
          Role.find_by(name: 'Admin')
        )
      )
    end

    it 'adds group permissions correctly' do
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

      click '.btn--success'

      expect(User.last).to have_attributes(
        email:       'test@example.com',
        user_groups: contain_exactly(
          have_attributes(group: group2, access: 'read')
        )
      )
    end
  end
end
