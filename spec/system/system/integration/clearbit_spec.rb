# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Integration > Clearbit', type: :system do
  let(:api_key)     { 'some_api_key' }
  let(:source)      { 'source1' }
  let(:destination) { 'destination1' }

  before do
    visit 'system/integration/clearbit'

    # enable clearbit
    check 'setting-switch', allow_label_click: true
  end

  context 'for clearbit config' do
    before do
      within :active_content, '.main' do
        fill_in 'api_key',	with: api_key

        within '.js-userSync .js-new' do
          fill_in 'source',	with: source
          fill_in 'destination',	with: destination
          click '.js-add'
        end

        click_button
      end
    end

    shared_examples 'showing set config' do
      it 'shows the set api_key' do
        within :active_content, '.main' do
          expect(page).to have_field('api_key', with: api_key)
        end
      end

      it 'shows the set source' do
        within :active_content, '.main .js-userSync' do
          expect(page).to have_field('source', with: source)
        end
      end

      it 'shows the set destination' do
        within :active_content, '.main .js-userSync' do
          expect(page).to have_field('destination', with: destination)
        end
      end
    end

    context 'when added' do
      it_behaves_like 'showing set config'
    end

    context 'when page is re-navigated back to integration page' do
      before do
        visit 'dashboard'
        visit 'system/integration/clearbit'
      end

      it_behaves_like 'showing set config'
    end

    context 'when page is reloaded' do
      before { refresh }

      it_behaves_like 'showing set config'
    end

    context 'when disabled with changed config' do
      before do
        # disable clearbit
        uncheck 'setting-switch', allow_label_click: true
      end

      let(:api_key) { '-empty-' }

      it_behaves_like 'showing set config'

      it 'does not have the old api key' do
        within :active_content, '.main' do
          expect(page).to have_no_field('api_key', with: 'some_api_key')
        end
      end
    end
  end
end
