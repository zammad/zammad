# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > sipgate.io', type: :system do
  let(:caller_id) { '0411234567' }
  let(:note)      { 'block spam caller id' }

  # Every setting update triggers a client notification which makes the frontend
  # re-fetch the whole settings collection (debounced, without any updated_at
  # guard). A re-fetch triggered by a previous update can read the config before
  # the latest update is committed and later overwrite the local settings
  # collection with that stale state - the database itself stays correct, so
  # wait_for_setting cannot catch this. In-app navigation back to the
  # integration page renders from the local collection only, so wait for it to
  # settle on the expected state before re-visiting the page.
  def wait_for_frontend_block_caller_ids(count)
    # Returns true when settled, otherwise a string naming the current state for
    #   the failure output. Also requires the ajax queue to be quiet, so a still
    #   running stale settings re-fetch cannot overwrite the collection right
    #   after this check (a re-fetch whose debounce timer has not fired yet
    #   remains invisible here - that residual window cannot be closed from the
    #   test side).
    state_js = <<~JS
      (function() {
        var setting = App.Setting.findByAttribute('name', 'sipgate_config');
        if (!setting) return 'sipgate_config not present in the frontend collection';

        if (App.Ajax.queue().length > 0 || $.active > 0) return 'settings requests still in flight';

        var ids = setting.state_current?.value?.inbound?.block_caller_ids || [];
        if (ids.length !== #{count}) return 'frontend collection has ' + ids.length + ' blocked caller id(s), expected #{count}';

        return true;
      })()
    JS

    result = nil

    begin
      wait.until do
        result = page.evaluate_script(state_js)
        result == true
      end
    rescue Selenium::WebDriver::Error::TimeoutError
      raise "Frontend settings collection did not settle: #{result}"
    end
  end

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

      click_on 'Save'
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

        wait_for_frontend_block_caller_ids(1)

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

        click_on 'Save'

        wait_for_setting('sipgate_config', { 'block_caller_ids' => [] }, key: 'inbound')
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

          wait_for_frontend_block_caller_ids(0)

          visit 'system/integration/sipgate'
        end

        it_behaves_like 'not showing removed caller id details'
      end
    end
  end
end
