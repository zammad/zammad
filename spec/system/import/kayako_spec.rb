# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Import Kayako', type: :system, set_up: false, authenticated_as: false, required_envs: %w[IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN IMPORT_KAYAKO_ENDPOINT_PASSWORD IMPORT_KAYAKO_ENDPOINT_USERNAME] do
  describe 'fields validation', :use_vcr do
    before do
      visit '#import'
      find('.js-kayako').click
    end

    let(:subdomain_field) { find_by_id('kayako-subdomain') }
    let(:email_field)     { find_by_id('kayako-email') }
    let(:password_field)  { find_by_id('kayako-password') }

    it 'invalid hostname' do
      subdomain_field.fill_in with: 'reallybadexample'

      expect(page).to have_css('.kayako-subdomain-error', text: 'The hostname could not be found.')
    end

    it 'valid hostname' do
      subdomain_field.fill_in with: 'reallybadexample'

      # wait for error to appear to validate it's hidden successfully
      find('.kayako-subdomain-error', text: 'The hostname could not be found.')

      subdomain_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']

      expect(page).to have_no_css('.kayako-subdomain-error', text: 'The hostname could not be found.')
    end

    it 'invalid credentials' do
      subdomain_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']
      find('.js-kayako-credentials').click
      email_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME']
      password_field.fill_in with: '1nv4l1dT0K3N'

      expect(page).to have_css('.kayako-password-error', text: 'The provided credentials are invalid.')
    end

    it 'valid credentials' do
      subdomain_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']
      find('.js-kayako-credentials').click
      email_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME']
      password_field.fill_in with: '1nv4l1dT0K3N'

      # wait for error to appear to validate it's hidden successfully
      expect(page).to have_css('.kayako-password-error', text: 'The provided credentials are invalid.')

      password_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_PASSWORD']

      expect(page).to have_no_css('.kayako-password-error', text: 'The provided credentials are invalid.')
    end

    it 'shows start button' do
      subdomain_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']
      find('.js-kayako-credentials').click
      email_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME']
      password_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_PASSWORD']

      expect(page).to have_css('.js-migration-start')
    end
  end

  describe 'import progress', :use_vcr do
    let(:subdomain_field) { find_by_id('kayako-subdomain') }
    let(:email_field)    { find_by_id('kayako-email') }
    let(:password_field) { find_by_id('kayako-password') }
    let(:job)            { ImportJob.find_by(name: 'Import::Kayako') }

    before do
      VCR.use_cassette 'system/import/kayako/import_progress_setup' do
        visit '#import'
        find('.js-kayako').click

        subdomain_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_SUBDOMAIN']
        find('.js-kayako-credentials').click
        email_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME']
        password_field.fill_in with: ENV['IMPORT_KAYAKO_ENDPOINT_PASSWORD']

        find('.js-migration-start').click

        await_empty_ajax_queue
      end
    end

    it 'shows groups progress' do
      job.update! result: { Groups: { sum: 3, total: 4 } }

      expect(page).to have_css('.js-groups .js-done', text: '3')
        .and(have_css('.js-groups .js-total', text: '4'))
    end

    it 'shows users progress' do
      job.update! result: { Users: { sum: 5, total: 7 } }

      expect(page).to have_css('.js-users .js-done', text: '5')
        .and(have_css('.js-users .js-total', text: '7'))
    end

    it 'shows organizations progress' do
      job.update! result: { Organizations: { sum: 3, total: 3 } }

      expect(page).to have_css('.js-organizations .js-done', text: '3')
        .and(have_css('.js-organizations .js-total', text: '3'))
    end

    it 'shows tickets progress' do
      job.update! result: { Tickets: { sum: 3, total: 5 } }

      expect(page).to have_css('.js-tickets .js-done', text: '3')
        .and(have_css('.js-tickets .js-total', text: '5'))
    end

    it 'shows login after import is finished and process login' do
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
