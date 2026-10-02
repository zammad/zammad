# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CalendarPublicHolidayResync, type: :db_migration do
  let(:ical_file) { 'calendar1.ics' }
  let(:ical_url)  { "http://test/#{ical_file}" }
  let(:feed)      { Digest::MD5.hexdigest(ical_url) }

  let(:custom_holiday) do
    { '2017-02-03' => { 'active' => true, 'summary' => 'Company day' } }
  end

  let(:outdated_feed_holiday) do
    { '2014-12-23' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed } }
  end

  let(:day_early_holidays) do
    {
      '2016-12-23' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
      '2017-12-23' => { 'active' => false, 'summary' => 'Christmas1', 'feed' => feed },
    }
  end

  let(:corrected_holidays) do
    {
      '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
      '2017-12-24' => { 'active' => false, 'summary' => 'Christmas1', 'feed' => feed },
    }
  end

  let(:remaining_feed_holidays) do
    {
      '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
      '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
      '2020-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
    }
  end

  before do
    allow(HostnameSafetyCheck).to receive(:validate!).and_return('1.2.3.4')
    travel_to Time.zone.parse('2017-08-24T01:04:44Z0')
  end

  context 'with a calendar synced from a feed' do
    let(:calendar) { create(:calendar, ical_url: ical_url) }

    before do
      stub_request(:get, ical_url)
        .to_return(body: Rails.root.join('test/data/calendar', ical_file).read)

      calendar.update!(public_holidays: stored_holidays)
    end

    context 'when feed entries were stored one day early' do
      let(:stored_holidays) { day_early_holidays.merge(custom_holiday).merge(outdated_feed_holiday) }

      it 'moves them to their day, keeps their flags, adds the missing feed days and leaves other entries alone' do
        expect { migrate }
          .to change { calendar.reload.public_holidays }
          .from(stored_holidays)
          .to(corrected_holidays.merge(remaining_feed_holidays).merge(custom_holiday).merge(outdated_feed_holiday))
      end

      it 'fetches the feed only once' do
        allow(Calendar).to receive(:fetch_parse).and_call_original

        migrate

        expect(Calendar).to have_received(:fetch_parse).once
      end

      context 'when the feed cannot be fetched' do
        before do
          stub_request(:get, ical_url).to_return(status: 404)
        end

        it 'keeps the existing entries' do
          expect { migrate }.not_to change { calendar.reload.public_holidays }
        end
      end

      context 'when the calendar no longer passes validation' do
        before do
          calendar.update_columns(business_hours: {})
          allow(Rails.logger).to receive(:error)
        end

        it 'keeps the existing entries' do
          expect { migrate }.not_to change { calendar.reload.public_holidays }
        end

        it 'logs the reason' do
          migrate

          expect(Rails.logger).to have_received(:error).with(%r{Calendar #{calendar.id}: .*There are no business hours configured})
        end
      end
    end

    context 'when feed entries on consecutive days were stored one day early' do
      let(:ical_file) { 'calendar2.ics' }

      let(:stored_holidays) do
        {
          '2016-12-23' => { 'active' => false, 'summary' => 'Christmas1', 'feed' => feed },
          '2016-12-24' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
        }
      end

      it 'moves both entries to their day and keeps their flags' do
        expect { migrate }
          .to change { calendar.reload.public_holidays.slice('2016-12-23', '2016-12-24', '2016-12-25') }
          .to(
            '2016-12-24' => { 'active' => false, 'summary' => 'Christmas1', 'feed' => feed },
            '2016-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
          )
      end
    end

    context 'when the corrected day of a day-early feed entry holds a custom entry' do
      let(:stored_holidays) do
        day_early_holidays.merge('2017-12-24' => { 'active' => true, 'summary' => 'Christmas party' })
      end

      before do
        # Saving re-attaches the feed digest to a day the initial sync filled, which a custom entry never carried.
        calendar.update_columns(public_holidays: stored_holidays)
      end

      it 'drops the misplaced entry and keeps the custom one' do
        expect { migrate }
          .to change { calendar.reload.public_holidays.slice('2017-12-23', '2017-12-24') }
          .to('2017-12-24' => { 'active' => true, 'summary' => 'Christmas party' })
      end
    end

    context 'when a feed entry with a summary the feed does not yield sits one day before an empty feed day' do
      let(:unmatched_holiday) do
        { '2018-12-23' => { 'active' => false, 'summary' => 'Heiligabend', 'feed' => feed } }
      end

      context 'with other entries of the feed stored one day early' do
        let(:stored_holidays) { day_early_holidays.merge(unmatched_holiday) }

        it 'leaves it where it is and adds the feed day next to it' do
          expect { migrate }
            .to change { calendar.reload.public_holidays.slice('2018-12-23', '2018-12-24') }
            .from(unmatched_holiday)
            .to(unmatched_holiday.merge('2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed }))
        end
      end

      context 'without other entries of the feed stored one day early' do
        let(:stored_holidays) { unmatched_holiday }

        it 'does not touch the calendar' do
          expect { migrate }.not_to change { calendar.reload.attributes }
        end
      end
    end

    context 'when a timed feed entry in a zone west of UTC was stored one day late' do
      let(:ical_file) { 'calendar4.ics' }

      let(:stored_holidays) do
        { '2017-01-20' => { 'active' => false, 'summary' => 'evening shift', 'feed' => feed } }
      end

      it 'moves it to its day and keeps its flag' do
        expect { migrate }
          .to change { calendar.reload.public_holidays.slice('2017-01-19', '2017-01-20') }
          .to('2017-01-19' => { 'active' => false, 'summary' => 'evening shift', 'feed' => feed })
      end
    end

    context 'when feed entries are stored on their day' do
      let(:stored_holidays) { corrected_holidays.merge(remaining_feed_holidays).merge(custom_holiday) }

      it 'does not touch the calendar' do
        expect { migrate }.not_to change { calendar.reload.attributes }
      end
    end

    context 'when no entry comes from the feed' do
      let(:stored_holidays) { custom_holiday }

      it 'does not fetch the feed' do
        allow(Calendar).to receive(:fetch_parse).and_call_original

        migrate

        expect(Calendar).not_to have_received(:fetch_parse)
      end

      it 'does not touch the calendar' do
        expect { migrate }.not_to change { calendar.reload.attributes }
      end
    end
  end

  context 'with a calendar without a feed' do
    let(:calendar) { create(:calendar, public_holidays: custom_holiday) }

    it 'does not touch the calendar' do
      expect { migrate }.not_to change { calendar.reload.attributes }
    end
  end
end
