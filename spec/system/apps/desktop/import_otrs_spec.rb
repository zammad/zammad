# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Mark this job as integration test to run it in the separate job with the required containers.
RSpec.describe 'Desktop > Import from OTRS', app: :desktop_view, authenticated_as: false, db_strategy: :reset, integration: true, integration_standalone: :otrs, performs_jobs: true, required_envs: %w[IMPORT_OTRS_ENDPOINT IMPORT_OTRS_ENDPOINT_KEY], set_up: false, type: :playwright do

  def button(name)
    page.get_by_role('button', name:, exact: true)
  end

  it 'performs the import and redirects to the login screen' do
    open_desktop('/')

    button('Or migrate from another system').click
    button('OTRS Beta').click
    button('Continue').click

    fill_field('URL', "#{ENV['IMPORT_OTRS_ENDPOINT']};Key=#{ENV['IMPORT_OTRS_ENDPOINT_KEY']}")
    button('Save and continue').click
    button('Start import').click

    wait_for_mutation('systemImportStart')

    allow(ActiveRecord::Base.connection).to receive(:close)
    perform_enqueued_jobs

    expect(main_content).to contain_text('Import finished successfully!')

    expect(User).to be_any
    expect(Group).to be_any
    expect(Organization).to be_any
    expect(Ticket).to be_any
  end
end
