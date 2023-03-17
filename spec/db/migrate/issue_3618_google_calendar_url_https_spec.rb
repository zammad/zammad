# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue3618GoogleCalendarUrlHttps, db_strategy: :reset, type: :db_migration do
  let(:url)      { 'http://www.google.com/calendar/ical/en.lithuanian%%23holiday%%40group.v.calendar.google.com/public/basic.ics' }
  let(:calendar) { create(:calendar, ical_url: url) }

  it 'migrates Google Calendar URLs' do
    expect { migrate }
      .to change { calendar.reload.ical_url.starts_with? 'https://' }
      .from(false)
      .to(true)
  end

  it 'other' do
    calendar.update_attribute(:business_hours, nil)

    expect { migrate }
      .to change { calendar.reload.ical_url.starts_with? 'https://' }
      .from(false)
      .to(true)
  end
end
