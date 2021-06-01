# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchIndexJob, type: :job do

  it 'calls search_index_update_backend on matching record' do
    user = create(:user)
    allow(::User).to receive(:find_by).with(id: user.id).and_return(user)
    allow(user).to receive(:search_index_update_backend)

    described_class.perform_now('User', user.id)
    expect(user).to have_received(:search_index_update_backend)
  end

  it "doesn't perform for non existing records" do
    id = 9999
    allow(::User).to receive(:find_by).with(id: id).and_return(nil)
    allow(SearchIndexBackend).to receive(:add)

    described_class.perform_now('User', id)
    expect(SearchIndexBackend).not_to have_received(:add)
  end

  it 'retries on exception' do
    allow(::User).to receive(:find_by).and_raise(RuntimeError)

    described_class.perform_now('User', 1)
    expect(described_class).to have_been_enqueued
  end
end
