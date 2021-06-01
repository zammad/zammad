# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Import Freshdesk', type: :system, set_up: false, authenticated_as: false do
  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    required_envs = %w[IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN IMPORT_FRESHDESK_ENDPOINT_KEY]
    required_envs.each do |key|
      skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
    end
  end

  describe 'fields validation', :use_vcr do
    before do
      visit '#import'
      find('.js-freshdesk').click
    end

    let(:subdomain_field) { find('#freshdesk-subdomain') }
    let(:token_field) { find('#freshdesk-api-token') }

    it 'invalid hostname' do
      subdomain_field.fill_in with: 'reallybadexample'

      expect(page).to have_css('.freshdesk-subdomain-error', text: 'Hostname not found!')
    end

    it 'valid hostname' do
      subdomain_field.fill_in with: 'reallybadexample'

      # wait for error to appear to validate it's hidden successfully
      find('.freshdesk-subdomain-error', text: 'Hostname not found!')

      subdomain_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN']

      expect(page).to have_no_css('.freshdesk-subdomain-error', text: 'Hostname not found!')
    end

    it 'invalid credentials' do
      subdomain_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN']
      find('.js-freshdesk-credentials').click
      token_field.fill_in with: '1nv4l1dT0K3N'

      expect(page).to have_css('.freshdesk-api-token-error', text: 'Invalid credentials!')
    end

    it 'valid credentials' do
      subdomain_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN']
      find('.js-freshdesk-credentials').click
      token_field.fill_in with: '1nv4l1dT0K3N'

      # wait for error to appear to validate it's hidden successfully
      expect(page).to have_css('.freshdesk-api-token-error', text: 'Invalid credentials!')

      token_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']

      expect(page).to have_no_css('.freshdesk-api-token-error', text: 'Invalid credentials!')
    end

    it 'shows start button' do
      subdomain_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN']
      find('.js-freshdesk-credentials').click
      token_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']

      expect(page).to have_css('.js-migration-start')
    end
  end

  describe 'import progress', :use_vcr do
    let(:subdomain_field) { find('#freshdesk-subdomain') }
    let(:token_field) { find('#freshdesk-api-token') }
    let(:job)         { ImportJob.find_by(name: 'Import::Freshdesk') }

    before do
      VCR.use_cassette 'system/import/freshdesk/import_progress_setup' do
        visit '#import'
        find('.js-freshdesk').click

        subdomain_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN']
        find('.js-freshdesk-credentials').click
        token_field.fill_in with: ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']

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

      expect(page).to have_text('Login')
    end
  end
end
