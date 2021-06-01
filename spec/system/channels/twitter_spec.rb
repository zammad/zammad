# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Twitter', :use_vcr, type: :system do

  context 'credentials' do

    before { visit '/#channels/twitter' }

    context 'incomplete' do
      it 'displays a 401 error modal' do
        within(:active_content) do
          find('.js-configApp').click

          modal_ready
          fill_in 'Twitter Consumer Key *',    with: 'some_key',    exact: true
          fill_in 'Twitter Consumer Secret *', with: 'some_secret', exact: true
          click_on 'Submit'

          expect(page).to have_css('.modal .alert', text: '401 Authorization Required')
        end
      end
    end

    context 'invalid' do
      it 'displays a 401 error modal' do
        within(:active_content) do
          find('.js-configApp').click

          modal_ready
          fill_in 'Twitter Consumer Key *',          with: 'some_key',                exact: true
          fill_in 'Twitter Consumer Secret *',       with: 'some_secret',             exact: true
          fill_in 'Twitter Access Token *',          with: 'some_oauth_token',        exact: true
          fill_in 'Twitter Access Token Secret *',   with: 'some_oauth_token_secret', exact: true
          fill_in 'Twitter Dev environment label *', with: 'some_env',                exact: true
          click_on 'Submit'

          expect(page).to have_css('.modal .alert', text: '401 Authorization Required')
        end
      end
    end
  end
end
