require 'rails_helper'

RSpec.describe 'Admin Panel > Channels > Twitter', :authenticated, :use_vcr, type: :system do
  context 'with incomplete credentials' do
    it 'displays a 401 error modal' do
      visit '/#channels/twitter'
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

  context 'with invalid credentials' do
    it 'displays a 401 error modal' do
      visit '/#channels/twitter'
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
