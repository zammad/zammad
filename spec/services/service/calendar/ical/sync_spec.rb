# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Calendar::Ical::Sync do
  # the AR callback chain is covered by the model spec; these examples isolate the sync itself
  subject(:execute) { described_class.execute(calendar:, save: false) }

  let(:calendar) { create(:calendar, ical_url: 'http://test/calendar1.ics', default: false) }
  let(:feed)     { Digest::MD5.hexdigest(calendar.ical_url) }

  before do
    allow(HostnameSafetyCheck).to receive(:validate!).and_return('1.2.3.4')
    stub_request(:get, 'http://test/calendar1.ics')
      .to_return(body: Rails.root.join('test/data/calendar/calendar1.ics').read)
    stub_request(:get, 'http://test/calendar2.ics')
      .to_return(body: Rails.root.join('test/data/calendar/calendar2.ics').read)
    travel_to Time.zone.parse('2017-08-24T01:04:44Z0')
  end

  describe 'caching' do
    it 'writes the feed URL to the cache (valid for 1 day)' do
      expect { described_class.execute(calendar:) }
        .to change { Rails.cache.read("CalendarIcal::#{calendar.id}") }
        .from(nil)
        .to({ ical_url: calendar.ical_url })
    end

    context 'when the sync is not saved' do
      it 'writes no cache entry' do
        expect { execute }
          .not_to change { Rails.cache.read("CalendarIcal::#{calendar.id}") }
          .from(nil)
      end

      it 'drops the cache entry of the previous feed' do
        described_class.execute(calendar:) # warm the cache
        calendar.ical_url = 'http://test/calendar2.ics'

        expect { execute }
          .to change { Rails.cache.read("CalendarIcal::#{calendar.id}") }
          .to(nil)
      end
    end

    # an unreachable cache backend only costs a repeated fetch, it must not fail the sync
    context 'when the cache backend raises' do
      before do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:write).and_call_original
        allow(Rails.cache).to receive(:delete).and_call_original
      end

      it 'completes a saved sync when the write fails' do
        allow(Rails.cache).to receive(:write).with("CalendarIcal::#{calendar.id}", any_args).and_raise(Errno::ENOSPC)

        expect(described_class.execute(calendar:)).to be(true)
      end

      it 'completes an unsaved sync when the delete fails' do
        allow(Rails.cache).to receive(:delete).with("CalendarIcal::#{calendar.id}").and_raise(Errno::ENOSPC)

        expect(execute).to be(true)
      end

      it 'treats a failing read as a cache miss' do
        described_class.execute(calendar:) # warm the cache
        allow(Rails.cache).to receive(:read).with("CalendarIcal::#{calendar.id}").and_raise(Errno::ENOSPC)
        WebMock.reset_executed_requests!

        execute

        expect(a_request(:get, calendar.ical_url)).to have_been_made
      end
    end

    context 'when the cache is warm' do
      before do
        described_class.execute(calendar:) # the create-time sync runs before the id exists, so it writes no cache
        WebMock.reset_executed_requests!
      end

      it 'does not fetch the feed again' do
        execute

        expect(a_request(:get, calendar.ical_url)).not_to have_been_made
      end

      it 'reports the sync as skipped' do
        expect(execute).to be(false)
      end

      # travel drops the memcached entry, so these cover a missing cache rather than a lapsed TTL
      it 'fetches the feed again once the cache is gone' do
        travel 2.days

        execute

        expect(a_request(:get, calendar.ical_url)).to have_been_made
      end

      it 'completes that sync without logging an error' do
        travel 2.days

        execute

        expect(calendar.last_log).to be_nil
      end
    end
  end

  describe 'merging events' do
    it 'is idempotent when the feed has not changed' do
      expect { execute }.not_to change(calendar, :public_holidays)
    end

    context 'when the date has advanced into a new recurrence' do
      before do
        calendar # create and sync
        travel 1.year
      end

      it 'appends newly computed event data to #public_holidays' do
        expect { execute }.to change(calendar, :public_holidays).to(
          '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2020-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2021-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
        )
      end
    end

    context 'when the iCal URL has changed' do
      before { calendar.assign_attributes(ical_url: 'http://test/calendar2.ics') }

      it 'replaces #public_holidays with event data computed from new iCal URL' do
        expect { execute }.to change(calendar, :public_holidays).to(
          '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2016-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
          '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2017-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
          '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2018-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
          '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2019-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
          '2020-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed },
          '2020-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => feed },
        )
      end
    end

    context 'when an entry was edited by hand' do
      before do
        calendar.public_holidays['2016-12-24'] = { 'active' => false, 'summary' => 'Not a holiday', 'feed' => feed }
      end

      it 'keeps the manual entry' do
        expect { execute }
          .not_to change { calendar.public_holidays['2016-12-24'] }
      end
    end

    # an entry an admin added by hand carries no 'feed' key, so no feed owns it
    context 'when an entry was added by hand' do
      before do
        calendar.public_holidays['2017-02-03'] = { 'active' => true, 'summary' => 'Company day' }
      end

      it 'survives a sync of the same feed' do
        expect { execute }.not_to change { calendar.public_holidays['2017-02-03'] }
      end

      it 'survives a changed iCal URL' do
        calendar.ical_url = 'http://test/calendar2.ics'

        expect { execute }.not_to change { calendar.public_holidays['2017-02-03'] }
      end

      it 'survives a removed iCal URL' do
        calendar.ical_url = nil

        expect { execute }.not_to change { calendar.public_holidays['2017-02-03'] }
      end
    end

    context 'without an iCal URL' do
      before do
        calendar.public_holidays['2016-12-24'] = { 'active' => true, 'summary' => 'Christmas1', 'feed' => feed }
        calendar.ical_url = nil
      end

      it 'drops the entries of the former feed' do
        expect { execute }.to change(calendar, :public_holidays).to({})
      end

      it 'does not log an error' do
        expect { execute }.not_to change(calendar, :last_log).from(nil)
      end
    end
  end

  describe 'error handling' do
    let(:calendar) { create(:calendar) }

    it 'logs errors to #last_log on invalid HTTP response' do
      error = instance_double(UserAgent::Result, success?: false, error: 'No such file https://example.com/cal.ics, 404!')
      allow(UserAgent).to receive(:get).and_return(error)

      calendar.update_column(:ical_url, 'https://example.com/cal.ics')

      execute

      expect(calendar.last_log).to include('No such file')
    end

    it 'logs errors to #last_log on HostnameSafetyCheck error' do
      allow(HostnameSafetyCheck).to receive(:validate!).and_raise(
        HostnameSafetyCheck::LoopbackIpError.new('127.0.0.1')
      )

      calendar.update_column(:ical_url, 'http://127.0.0.1/cal.ics')

      execute

      expect(calendar.last_log).to include('The hostname is a loopback IP')
    end

    it 'clears a previous #last_log on a successful sync' do
      calendar.update_column(:ical_url, 'http://test/calendar1.ics')
      calendar.last_log = 'previous failure'

      expect { execute }.to change(calendar, :last_log).to(nil)
    end
  end

  describe 'stamping last_sync' do
    before { calendar } # create and sync, stamping last_sync at the frozen time

    it 'is stamped on a successful sync' do
      travel 1.year # advance the frozen clock, so a new stamp differs

      expect { execute }.to change(calendar, :last_sync)
    end

    it 'is stamped when the sync fails' do
      allow(Service::Calendar::Ical::Fetch).to receive(:execute).and_raise('boom')
      travel 1.year # advance the frozen clock, so a new stamp differs

      expect { execute }.to change(calendar, :last_sync)
    end

    it 'is not stamped when the sync is skipped because the cache is warm' do
      described_class.execute(calendar:) # warm the cache
      calendar.last_sync = nil # travelling instead would drop the cache entry

      expect { execute }.not_to change(calendar, :last_sync).from(nil)
    end
  end

  describe 'persistence' do
    before do
      calendar      # create and sync
      travel 1.year # reach the next recurrence, so the feed changes #public_holidays
    end

    it 'saves the calendar' do
      expect { described_class.execute(calendar:) }
        .to change { Calendar.find(calendar.id).public_holidays }
    end

    it 'saves the error log when the sync fails' do
      allow(Service::Calendar::Ical::Fetch).to receive(:execute).and_raise('boom')

      described_class.execute(calendar:)

      expect(Calendar.find(calendar.id).last_log).to include('boom')
    end

    it 'does not save with save: false' do
      expect { described_class.execute(calendar:, save: false) }
        .not_to change { Calendar.find(calendar.id).public_holidays }
    end

    context 'when the calendar cannot be saved' do
      before { calendar.business_hours = {} }

      it 'reports the sync as failed' do
        expect(described_class.execute(calendar:)).to be(false)
      end

      it 'does not mark the calendar as synced' do
        expect { described_class.execute(calendar:) }
          .not_to change { Rails.cache.read("CalendarIcal::#{calendar.id}") }
      end
    end

    context 'when the cache is warm and the sync is skipped' do
      before { described_class.execute(calendar:) } # warm the cache at the current time

      it 'does not save' do
        calendar.name = 'not saved by a skipped sync'

        described_class.execute(calendar:)

        expect(Calendar.find(calendar.id).name).not_to eq(calendar.name)
      end
    end
  end
end
