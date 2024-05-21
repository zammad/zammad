# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::CalendarSubscription::Update do
  let(:user)    { create(:user) }
  let(:service) { described_class.new(user, input:) }

  let(:input)   do
    {
      alarm:      true,
      new_open:   { own: false, not_assigned: true },
      pending:    { own: true, not_assigned: true },
      escalation: { own: false, not_assigned: false },
    }
  end

  it 'sets alarm and type-specific options' do
    service.execute

    expect(user.preferences.dig(:calendar_subscriptions, :tickets))
      .to include(
        alarm:      true,
        new_open:   include(own: false, not_assigned: true),
        pending:    include(own: true, not_assigned: true),
        escalation: include(own: false, not_assigned: false),
      )
  end
end
