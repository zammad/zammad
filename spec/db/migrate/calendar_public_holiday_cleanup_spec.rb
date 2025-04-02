# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CalendarPublicHolidayCleanup, type: :db_migration do
  let(:ical_url)                            { Rails.root.join('test/data/calendar/calendar_duplicate_check.ics') }
  let(:calendar_with_public_holiday)        { create(:calendar, ical_url: ical_url) }
  let(:calendar_without_public_holiday)     { create(:calendar, ical_url: ical_url) }
  let(:calendar_without_ical_url)           { create(:calendar) }
  let(:calendar_with_custom_public_holiday) { create(:calendar, ical_url: ical_url) }
  let(:feed)                                { Digest::MD5.hexdigest(ical_url.to_s) }

  let(:public_holidays) do
    {
      '2019-01-01' => { 'active' => true, 'feed' => feed, 'summary' => 'Neujahrstag' },
      '2019-01-02' => { 'active' => true, 'feed' => feed, 'summary' => 'Neujahrstag' },
      '2019-04-22' => { 'active' => true, 'feed' => feed, 'summary' => 'Ostermontag' },
      '2019-04-23' => { 'active' => true, 'feed' => feed, 'summary' => 'Ostermontag' },
    }
  end

  let(:public_holidays_uniq) do
    {
      '2019-01-01' => { 'active' => true, 'feed' => feed, 'summary' => 'Neujahrstag' },
      '2019-04-22' => { 'active' => true, 'feed' => feed, 'summary' => 'Ostermontag' },
    }
  end

  let(:public_holidays_custom) do
    {
      '2019-02-03' => { 'active' => true, 'summary' => 'Super Bowl LIII' },
    }
  end

  let(:public_holidays_uniq_custom) do
    public_holidays_custom.merge(public_holidays_uniq)
  end

  let(:public_holidays_non_uniq_custom) do
    public_holidays.merge(public_holidays_custom)
  end

  before do
    travel_to Time.zone.parse('2017-08-24T01:04:44Z0')

    calendar_with_public_holiday && calendar_without_public_holiday && calendar_without_ical_url && calendar_with_custom_public_holiday

    calendar_with_public_holiday.update!(public_holidays: public_holidays)
    calendar_without_ical_url.update!(public_holidays: public_holidays)
    calendar_with_custom_public_holiday.update!(public_holidays: public_holidays_non_uniq_custom)
  end

  it 'does not update calendars without public holidays/ical_urls' do
    expect { migrate }.to not_change { calendar_without_public_holiday }.and not_change { calendar_without_ical_url }
  end

  it 'does remove duplicates' do
    expect { migrate }.to change { calendar_with_public_holiday.reload.public_holidays }.from(public_holidays).to(public_holidays_uniq)
  end

  it 'does remove duplicates but keeps custom entries' do
    expect { migrate }.to change { calendar_with_custom_public_holiday.reload.public_holidays }.from(public_holidays_non_uniq_custom).to(public_holidays_uniq_custom)
  end
end
