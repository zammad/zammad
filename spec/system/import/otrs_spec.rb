# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Mark this job as integration test to run it in the separate job with the required containers.
RSpec.describe 'Import from OTRS', authenticated_as: false, db_strategy: :reset, integration: true, integration_standalone: :otrs, performs_jobs: true, required_envs: %w[IMPORT_OTRS_ENDPOINT IMPORT_OTRS_ENDPOINT_KEY], set_up: false, type: :system do

  let(:job) { ImportJob.find_by(name: 'Import::OTRS') }

  it 'performs the import and redirects to the login screen' do
    visit '#import'
    click '.js-otrs'
    click '.js-download:last-child'
    click '.js-otrs-link'

    find('#otrs-link').fill_in(with: "#{ENV['IMPORT_OTRS_ENDPOINT']};Key=invalid_key")

    expect(page).to have_text('Invalid API key')

    find('#otrs-link').fill_in(with: "#{ENV['IMPORT_OTRS_ENDPOINT']};Key=#{ENV['IMPORT_OTRS_ENDPOINT_KEY']}", fill_options: { clear: :backspace })
    expect(page).to have_no_text('Invalid API Key')

    click '.js-migration-check'
    expect(page).to have_text('Many dynamic fields were found')

    click '.js-migration-start'
    await_empty_ajax_queue

    # Suppress to avoid: #<Thread:0x000000012d5ef5f0 /Users/mg/wz/zammad/lib/import/otrs.rb:70 run> terminated with exception (report_on_exception is true):
    allow(ActiveRecord::Base.connection).to receive(:close)
    perform_enqueued_jobs

    expect(page).to have_css('#login')
  end
end
