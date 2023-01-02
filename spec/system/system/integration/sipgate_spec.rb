# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > sipgate.io', type: :system do
  let(:caller_id) { '0411234567' }
  let(:note)      { 'block spam caller id' }

  before do
    visit 'system/integration/sipgate'

    # enable sipgate
    check 'setting-switch', allow_label_click: true
  end

  context 'for Blocked caller ids based on sender caller id' do
    before do
      within :active_content, '.main .js-inboundBlockCallerId' do
        fill_in 'caller_id',	with: caller_id
        fill_in 'note',	with: note
        click '.js-add'
      end

      click_button
    end

    shared_examples 'showing added caller id details' do
      it 'shows the blocked caller id' do
        within :active_content, '.main .js-inboundBlockCallerId' do
          expect(page).to have_field('caller_id', with: caller_id)
        end
      end

      it 'shows the blocked caller id note' do
        within :active_content, '.main .js-inboundBlockCallerId' do
          expect(page).to have_field('note', with: note)
        end
      end
    end

    context 'when added' do
      it_behaves_like 'showing added caller id details'
    end

    context 'when page is re-navigated back to integration page' do
      before do
        visit 'dashboard'
        visit 'system/integration/sipgate'
      end

      it_behaves_like 'showing added caller id details'
    end

    context 'when page is reloaded' do
      before { refresh }

      it_behaves_like 'showing added caller id details'
    end

    context 'when removed' do
      before do
        within :active_content, '.main .js-inboundBlockCallerId' do
          click '.js-remove'
        end

        click_button
      end

      shared_examples 'not showing removed caller id details' do
        it 'does not show the blocked caller id' do
          within :active_content, '.main .js-inboundBlockCallerId' do
            expect(page).to have_no_field('caller_id', with: caller_id)
          end
        end

        it 'does not show the blocked caller id note' do
          within :active_content, '.main .js-inboundBlockCallerId' do
            expect(page).to have_no_field('note', with: note)
          end
        end
      end

      it_behaves_like 'not showing removed caller id details'

      context 'when page is re-navigated back to integration page' do
        before do
          visit 'dashboard'
          visit 'system/integration/sipgate'
        end

        it_behaves_like 'not showing removed caller id details'
      end
    end
  end
end
