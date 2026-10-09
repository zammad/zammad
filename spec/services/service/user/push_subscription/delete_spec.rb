# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::PushSubscription::Delete do
  subject(:service_result) { described_class.with_current_user(agent).execute(endpoint:) }

  let(:agent)         { create(:agent) }
  let(:subscription)  { create(:push_subscription, user: agent) }
  let(:endpoint)      { subscription.endpoint }

  it 'removes the subscription of the current user' do
    subscription

    expect { service_result }.to change(PushSubscription, :count).by(-1)
  end

  context 'when the endpoint belongs to another user' do
    let(:subscription) { create(:push_subscription) }

    it 'keeps the subscription' do
      subscription

      expect { service_result }.not_to change(PushSubscription, :count)
    end
  end

  context 'when the endpoint is unknown' do
    let(:endpoint) { 'https://fcm.googleapis.com/fcm/send/unknown' }

    it 'succeeds without changes' do
      expect(service_result).to be(true)
    end
  end
end
