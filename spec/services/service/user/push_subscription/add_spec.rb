# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PushSubscription::Add do
  subject(:service_result) { described_class.with_current_user(agent).execute(endpoint:, keys:) }

  let(:agent)      { create(:agent) }
  let(:endpoint)   { 'https://fcm.googleapis.com/fcm/send/new' }
  let(:p256dh)     { Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false) }
  let(:auth)       { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }
  let(:keys)       { { p256dh:, auth: } }

  it 'stores the subscription for the current user' do
    expect(service_result).to have_attributes(
      user:     agent,
      endpoint: endpoint,
      p256dh:   p256dh,
      auth:     auth,
    )
  end

  it 'creates one record' do
    expect { service_result }.to change(PushSubscription, :count).by(1)
  end

  context 'when the endpoint is already registered' do
    let(:other_agent)  { create(:agent) }
    let!(:existing)    { create(:push_subscription, user: other_agent, endpoint:) }

    it 'moves the subscription to the current user with the current keys', :aggregate_failures do
      expect { service_result }.not_to change(PushSubscription, :count)

      expect(existing.reload).to have_attributes(user: agent, p256dh:, auth:)
    end
  end

  context 'when the keys are missing' do
    let(:keys) { { p256dh: '', auth: '' } }

    it 'raises a validation error' do
      expect { service_result }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
