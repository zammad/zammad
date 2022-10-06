# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Import Zendesk', type: :system, set_up: false, authenticated_as: false, required_envs: %w[IMPORT_ZENDESK_ENDPOINT IMPORT_ZENDESK_ENDPOINT_KEY IMPORT_ZENDESK_ENDPOINT_USERNAME] do

  import_zendesk_url = ENV['IMPORT_ZENDESK_ENDPOINT'].remove(%r{/api/v2/?})

  describe 'fields validation', :use_vcr do
    before do
      visit '#import'
      find('.js-zendesk').click
    end

    let(:url_field)   { find_by_id('zendesk-url') }
    let(:email_field) { find_by_id('zendesk-email') }
    let(:token_field) { find_by_id('zendesk-api-token') }

    it 'invalid hostname' do
      url_field.fill_in with: 'https://reallybadexample.zendesk.com/'

      expect(page).to have_css('.zendesk-url-error', text: 'The hostname could not be found.')
    end

    it 'valid hostname' do
      url_field.fill_in with: 'https://reallybadexample.zendesk.com/'

      # wait for error to appear to validate it's hidden successfully
      find('.zendesk-url-error', text: 'The hostname could not be found.')

      url_field.fill_in with: import_zendesk_url

      expect(page).to have_no_css('.zendesk-url-error', text: 'The hostname could not be found.')
    end

    it 'invalid credentials' do
      url_field.fill_in with: import_zendesk_url
      find('.js-zendesk-credentials').click
      email_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
      token_field.fill_in with: '1nv4l1dT0K3N'

      expect(page).to have_css('.zendesk-api-token-error', text: 'The provided credentials are invalid.')
    end

    it 'valid credentials' do
      url_field.fill_in with: import_zendesk_url
      find('.js-zendesk-credentials').click
      email_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
      token_field.fill_in with: '1nv4l1dT0K3N'

      # wait for error to appear to validate it's hidden successfully
      expect(page).to have_css('.zendesk-api-token-error', text: 'The provided credentials are invalid.')

      token_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_KEY']

      expect(page).to have_no_css('.zendesk-api-token-error', text: 'The provided credentials are invalid.')
    end

    it 'shows start button' do
      url_field.fill_in with: import_zendesk_url
      find('.js-zendesk-credentials').click
      email_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
      token_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_KEY']

      expect(page).to have_css('.js-migration-start')
    end
  end

  describe 'import progress', :use_vcr do
    let(:url_field)   { find_by_id('zendesk-url') }
    let(:email_field) { find_by_id('zendesk-email') }
    let(:token_field) { find_by_id('zendesk-api-token') }
    let(:job)         { ImportJob.find_by(name: 'Import::Zendesk') }

    before do
      VCR.use_cassette 'system/import/zendesk/import_progress_setup' do
        visit '#import'
        find('.js-zendesk').click

        url_field.fill_in with: import_zendesk_url
        find('.js-zendesk-credentials').click
        email_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME']
        token_field.fill_in with: ENV['IMPORT_ZENDESK_ENDPOINT_KEY']

        find('.js-migration-start').click

        await_empty_ajax_queue
      end
    end

    it 'shows groups progress' do
      job.update! result: { Groups: { sum: 3, total: 5 } }

      expect(page).to have_css('.js-groups .js-done', text: '3')
        .and(have_css('.js-groups .js-total', text: '5'))
    end

    it 'shows users progress' do
      job.update! result: { Users: { sum: 5, total: 9 } }

      expect(page).to have_css('.js-users .js-done', text: '5')
        .and(have_css('.js-users .js-total', text: '9'))
    end

    it 'shows organizations progress' do
      job.update! result: { Organizations: { sum: 3, total: 5 } }

      expect(page).to have_css('.js-organizations .js-done', text: '3')
        .and(have_css('.js-organizations .js-total', text: '5'))
    end

    it 'shows tickets progress' do
      job.update! result: { Tickets: { sum: 3, total: 5 } }

      expect(page).to have_css('.js-tickets .js-done', text: '3')
        .and(have_css('.js-tickets .js-total', text: '5'))
    end

    it 'shows login after import is finished' do
      job.update! finished_at: Time.zone.now

      Rake::Task['zammad:setup:auto_wizard'].execute

      expect(page).to have_text(Setting.get('fqdn'))

      # Check that the login is working and also the left navigation side bar is visible.
      login(
        username: 'admin@example.com',
        password: 'test',
      )
    end
  end
end
