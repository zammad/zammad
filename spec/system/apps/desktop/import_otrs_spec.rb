# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Mark this job as integration test to run it in the separate job with the required containers.
RSpec.describe 'Desktop > Import from OTRS', app: :desktop_view, authenticated_as: false, db_strategy: :reset, integration: true, integration_standalone: :otrs, performs_jobs: true, required_envs: %w[IMPORT_OTRS_ENDPOINT IMPORT_OTRS_ENDPOINT_KEY], set_up: false, type: :system do

  it 'performs the import and redirects to the login screen' do
    visit '/'

    click_on 'Or migrate from another system'
    click_on 'OTRS'
    click_on 'Continue'

    find_input('URL').type("#{ENV['IMPORT_OTRS_ENDPOINT']};Key=#{ENV['IMPORT_OTRS_ENDPOINT_KEY']}")
    click_on 'Save and Continue'
    click_on 'Start Import'

    wait_for_gql 'apps/desktop/pages/guided-setup/graphql/mutations/systemImportStart.graphql'

    allow(ActiveRecord::Base.connection).to receive(:close)
    perform_enqueued_jobs

    expect(page).to have_text('Import finished successfully!')

    expect(User).to be_any
    expect(Group).to be_any
    expect(Organization).to be_any
    expect(Ticket).to be_any
  end
end
