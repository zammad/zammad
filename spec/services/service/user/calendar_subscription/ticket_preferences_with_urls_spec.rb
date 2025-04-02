# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::CalendarSubscription::TicketPreferencesWithUrls do
  let(:user)     { create(:user) }
  let(:service)  { described_class.new(user) }
  let(:base_url) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}" }

  let(:mocked_data) do
    {
      tickets: {
        alarm:      true,
        new_open:   { own: true, not_assigned: false },
        pending:    { own: true, not_assigned: true },
        escalation: { own: true, not_assigned: false },
      }
    }
  end

  before do
    allow_any_instance_of(Service::User::CalendarSubscription::Preferences)
      .to receive(:execute).and_return(mocked_data)
  end

  it 'returns preferences and URLs with FQDN' do
    expect(service.execute)
      .to include(
        combined_url:   "#{base_url}/ical/tickets",
        global_options: include(alarm: true),
        new_open:       include(
          url:     "#{base_url}/ical/tickets/new_open",
          options: include(own: true, not_assigned: false)
        ),
        pending:        include(
          url:     "#{base_url}/ical/tickets/pending",
          options: include(own: true, not_assigned: true)
        ),
        escalation:     include(
          url:     "#{base_url}/ical/tickets/escalation",
          options: include(own: true, not_assigned: false)
        ),
      )
  end
end
