# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Icinga', type: :system do
  let(:icinga_sender)     { 'some@othersender.com' }
  let(:icinga_auto_close) { 'no' }

  before do
    visit 'system/integration/icinga'

    # enable icinga
    check 'setting-switch', allow_label_click: true
  end

  context 'for icinga config' do
    before do
      within :active_content, '.main' do
        fill_in 'icinga_sender',	with: icinga_sender
        select icinga_auto_close,	from: 'icinga_auto_close'
        click_button
      end
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

    context 'when disabled with changed config' do
      before do
        # disable icinga
        uncheck 'setting-switch', allow_label_click: true
      end

      let(:icinga_sender) { 'icinga@monitoring.example.com' }
      let(:icinga_auto_close) { 'yes' }

      it_behaves_like 'showing set config'
    end
  end
end
