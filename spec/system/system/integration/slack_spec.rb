# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Slack', type: :system do
  let(:group_ids) { 'Users' }
  let(:webhook)   { 'http://some_url/webhook/123' }
  let(:username)  { 'someuser' }

  before do
    visit 'system/integration/slack'

    # enable slack
    check 'setting-switch', allow_label_click: true
  end

  context 'for slack config' do
    before do
      within :active_content, '.main' do
        select group_ids,	from: 'group_ids'
        fill_in 'webhook',	with: webhook
        fill_in 'username',	with: username
        click_button
      end
    end

    shared_examples 'showing set config' do
      it 'shows the set group_ids' do
        within :active_content, '.main' do
          expect(page).to have_field('group_ids', type: 'select', text: group_ids)
        end
      end

      it 'shows the set webhook' do
        within :active_content, '.main' do
          expect(page).to have_field('webhook', with: webhook)
        end
      end

      it 'shows the set username' do
        within :active_content, '.main' do
          expect(page).to have_field('username', with: username)
        end
      end
    end

    context 'when added' do
      it_behaves_like 'showing set config'
    end

    context 'when page is re-navigated back to integration page' do
      before do
        visit 'dashboard'
        visit 'system/integration/slack'
      end

      it_behaves_like 'showing set config'
    end

    context 'when page is reloaded' do
      before { refresh }

      it_behaves_like 'showing set config'
    end
  end
end
