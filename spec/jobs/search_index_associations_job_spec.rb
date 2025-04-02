# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexAssociationsJob, performs_jobs: true, searchindex: true, type: :job do
  let(:organization) { create(:organization) }
  let(:user)         { create(:user, organization: organization) }

  before do
    user
    searchindex_model_reload([User, Organization])
    perform_enqueued_jobs
  end

  it 'does not enqueue new jobs if not needed', :aggregate_failures do
    organization.update(name: SecureRandom.uuid)
    expect(described_class).to have_been_enqueued

    # first run will have updated the organization
    # and so it will requeue the job
    perform_enqueued_jobs
    expect(described_class).to have_been_enqueued

    # second job should not requeue again
    allow(SearchIndexBackend).to receive(:update_by_query).and_return({ 'total' => 0 }) # fake it because of unstable version conflicts in ES
    perform_enqueued_jobs
    expect(described_class).not_to have_been_enqueued
  end

  it 'does update objects until there are no conflicts or unprocessed left' do
    organization.update(name: SecureRandom.uuid)
    result = false
    30.times do
      result = described_class.perform_now('Organization', organization.id)
      puts 'Waiting for elastic search to complete mass update...' # rubocop:disable Rails/Output
      break if result == true

      sleep 1
    end
    expect(result).to be(true)
  end
end
