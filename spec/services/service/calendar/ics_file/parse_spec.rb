# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Calendar::IcsFile::Parse do
  subject(:service) { described_class.new(current_user: user) }

  let(:user)          { create(:user) }
  let(:calendar_file) { create(:store, :ics) }

  it 'parses the calendar file' do
    expect(service.execute(file: calendar_file)).to eq(
      events:   [{
        title:       'Test Summary',
        location:    'https://us.zoom.us/j/example?pwd=test',
        start_date:  '2021-07-27T10:30:00.000+02:00',
        end_date:    '2021-07-27T12:00:00.000+02:00',
        attendees:   ['M.bob@example.com', 'J.doe@example.com'],
        organizer:   'f.sample@example.com',
        description: 'Test description'
      }],
      filename: 'basic.ics',
      type:     'text/calendar'
    )
  end
end
