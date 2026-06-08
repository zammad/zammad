# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::CalendarSubscription::Update do
  subject(:service_result) { described_class.with_current_user(user).execute(input:) }

  let(:user) { create(:user) }

  let(:input) do
    {
      alarm:      true,
      new_open:   { own: false, not_assigned: true },
      pending:    { own: true, not_assigned: true },
      escalation: { own: false, not_assigned: false },
    }
  end

  it 'sets alarm and type-specific options' do
    service_result

    expect(user.reload.preferences.dig(:calendar_subscriptions, :tickets))
      .to include(
        alarm:      true,
        new_open:   include(own: false, not_assigned: true),
        pending:    include(own: true, not_assigned: true),
        escalation: include(own: false, not_assigned: false),
      )
  end
end
