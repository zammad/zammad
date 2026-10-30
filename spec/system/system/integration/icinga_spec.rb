# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Icinga', type: :system do
  let(:icinga_sender)     { 'some@othersender.com' }
  let(:icinga_auto_close) { 'no' }

  context 'when enabled with the switch' do
    before { visit 'system/integration/icinga' }

    it 'stores the integration as enabled' do
      expect(page).to have_unchecked_field('setting-switch', visible: :all)

      check 'setting-switch', allow_label_click: true
      wait_for_setting('icinga_integration', true)
    end
  end

  context 'for icinga config' do
    # Enabled in the backend: enabling it in the page makes the frontend re-fetch all settings,
    #   and a re-fetch that reads before the config is saved overwrites the config in the frontend.
    before do
      Setting.set('icinga_integration', true)

      visit 'system/integration/icinga'

      within :active_content, '.main' do
        fill_in 'icinga_sender',	with: icinga_sender
        select icinga_auto_close,	from: 'icinga_auto_close'
        click_on 'Submit'
      end

      wait_for_setting('icinga_sender', icinga_sender)
    end

    shared_examples 'showing set config' do
      it 'shows the set icinga_sender' do
        within :active_content, '.main' do
          expect(page).to have_field('icinga_sender', with: icinga_sender)
        end
      end

      it 'shows the set icinga_auto_close' do
        within :active_content, '.main' do
          expect(page).to have_field('icinga_auto_close', type: 'select', text: icinga_auto_close)
        end
      end
    end

    context 'when added' do
      it_behaves_like 'showing set config'
    end

    context 'when page is re-navigated back to integration page' do
      before do
        visit 'dashboard'
        visit 'system/integration/icinga'
      end

      it_behaves_like 'showing set config'
    end

    context 'when page is reloaded' do
      before { refresh }

      it_behaves_like 'showing set config'
    end

    context 'when disabled' do
      before do
        uncheck 'setting-switch', allow_label_click: true
        wait_for_setting('icinga_integration', false)
      end

      it_behaves_like 'showing set config'
    end
  end
end
