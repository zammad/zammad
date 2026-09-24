# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue6384CleanupCtiCallerIdsFromTechnicalColumns, :aggregate_failures, type: :db_migration do
  let!(:user) do
    create(:user, :without_email, login: 'auto-4358116e-5280-4687-b71a-4a4b619bd42c', phone: '+49 30 609812345')
  end

  let!(:other_user) { create(:user, phone: '+49 30 609812346') }

  # The rows the login used to yield, which the sync no longer creates.
  before do
    %w[4358116 52804687].each { |number| create(:cti_caller_id, o: user, user: user, caller_id: number) }
  end

  it 'removes the caller IDs a login yielded and keeps the phone number' do
    migrate

    expect(Cti::CallerId.where(user_id: user.id).pluck(:caller_id)).to eq(['4930609812345'])
  end

  it 'leaves a user alone whose columns yield no such numbers' do
    expect { migrate }.not_to change { Cti::CallerId.where(user_id: other_user.id).pluck(:id) }
  end
end
