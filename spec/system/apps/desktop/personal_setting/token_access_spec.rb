# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Personal Setting > Token Access', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  def open_new_token_flyout
    visit '/personal-setting/token-access'
    click_on 'New personal access token'
  end

  def permission_switch(name)
    find("[role=\"switch\"][id$=\"_#{name}\"]")
  end

  def expect_token_created(name, permission)
    expect(page).to have_text('For security reasons, the API token is shown only once.')

    expect(agent.tokens.find_by(action: 'api'))
      .to have_attributes(name: name, preferences: include('permission' => [permission]))
  end

  context 'when a granted permission has no priority' do
    let(:custom_permission) { create(:permission, name: 'custom_permission', label: 'Custom permission', preferences: {}) }
    let(:custom_role)       { create(:role, permissions: [custom_permission]) }
    let(:agent)             { create(:agent, roles: [Role.find_by(name: 'Agent'), custom_role]) }

    it 'lists the permission and creates a token with it' do
      open_new_token_flyout

      within '#flyout-new-access-token' do
        fill_in 'Name', with: 'Custom token'

        permission_switch('custom_permission').click

        click_on 'Create'
      end

      expect_token_created('Custom token', 'custom_permission')
    end
  end

  context 'when the parent of a granted permission is inactive' do
    before { Permission.find_by!(name: 'chat').update!(active: false) }

    it 'lists the permission below a disabled placeholder and creates a token with it' do
      open_new_token_flyout

      within '#flyout-new-access-token' do
        fill_in 'Name', with: 'Chat token'

        expect(permission_switch('chat')['aria-disabled']).to eq('true')

        permission_switch('chat').ancestor('[role="treeitem"]').find('[aria-label="Toggle group"]').click
        permission_switch('chat.agent').click

        click_on 'Create'
      end

      expect_token_created('Chat token', 'chat.agent')
    end
  end
end
