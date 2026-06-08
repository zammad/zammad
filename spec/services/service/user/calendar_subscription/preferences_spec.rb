# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::CalendarSubscription::Preferences do
  subject(:service_result) { described_class.with_current_user(user).execute }

  let(:user) { create(:user) }

  context 'when user has no preferences' do
    it 'returns default ticket preferences' do
      expect(service_result).to include(
        tickets: include(
          alarm:      false,
          new_open:   include(own: true, not_assigned: false),
          pending:    include(own: true, not_assigned: false),
          escalation: include(own: true, not_assigned: false),
        )
      )
    end
  end

  context 'when user has custom preferences' do
    before do
      Service::User::CalendarSubscription::Update
        .with_current_user(user)
        .execute(input: {
                   alarm:      true,
                   new_open:   { own: false, not_assigned: true },
                   pending:    { own: true, not_assigned: true },
                   escalation: { own: false, not_assigned: false },

                 })
    end

    it 'returns custom preferences' do
      expect(service_result).to include(
        tickets: include(
          alarm:      true,
          new_open:   include(own: false, not_assigned: true),
          pending:    include(own: true, not_assigned: true),
          escalation: include(own: false, not_assigned: false),
        )
      )
    end
  end
end
