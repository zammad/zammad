# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe Calendar, type: :model do
  subject(:calendar) { create(:calendar) }

  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'

  describe 'attributes' do
    describe '#default' do
      before { expect(described_class.pluck(:default)).to eq([true]) }

      context 'when set to true on creation' do
        subject(:calendar) { build(:calendar, default: true) }

        it 'stays true and sets all other calendars to default: false' do
          expect { calendar.tap(&:save).reload }.not_to change(calendar, :default)
          expect(described_class.where(default: true) - [calendar]).to be_empty
        end
      end

      context 'when set to true on update' do
        subject(:calendar) { create(:calendar, default: false) }

        before { calendar.default = true }

        it 'stays true and sets all other calendars to default: false' do
          expect { calendar.tap(&:save).reload }.not_to change(calendar, :default)
          expect(described_class.where(default: true) - [calendar]).to be_empty
        end
      end

      context 'when set to false on update' do
        it 'sets default: true on earliest-created calendar' do
          expect { described_class.first.update(default: false) }
            .not_to change { described_class.first.default }
        end
      end

      context 'when default calendar is destroyed' do
        subject!(:calendar) { create(:calendar, default: false) }

        it 'sets default: true on earliest-created remaining calendar' do
          expect { described_class.first.destroy }
            .to change { calendar.reload.default }.to(true)
        end

        context 'when sla has destroyed calendar set' do
          let(:sla) { create(:sla, calendar: described_class.first) }

          before do
            sla
          end

          it 'sets the new default calendar to the sla' do
            expect { described_class.first.destroy }
              .to change { sla.reload.calendar }.to(calendar)
          end
        end
      end
    end
  end

  describe '.sync' do
    let(:calendar_ical_sync_service) { Service::Calendar::Ical::Sync }
    let(:broken_calendar)            { create(:calendar, ical_url: 'http://test/calendar1.ics', default: false) }
    let(:working_calendar)           { create(:calendar, ical_url: 'http://test/calendar2.ics', default: false) }

    before do
      allow(calendar_ical_sync_service).to receive(:execute) # the stub has to be in place before the create-time sync

      broken_calendar
      working_calendar
    end

    context 'when one calendar raises' do
      before do
        allow(Rails.logger).to receive(:error)
        allow(calendar_ical_sync_service)
          .to receive(:execute).with(calendar: broken_calendar).and_raise('feed is broken')
      end

      it 'syncs the remaining calendars' do
        described_class.sync

        expect(calendar_ical_sync_service).to have_received(:execute).with(calendar: working_calendar)
      end

      it 'logs the error of the failing calendar' do
        described_class.sync

        expect(Rails.logger).to have_received(:error).with("Calendar ##{broken_calendar.id}: #<RuntimeError: feed is broken>")
      end

      it 'logs the backtrace of the failing calendar' do
        described_class.sync

        expect(Rails.logger).to have_received(:error).with(%r{app/models/calendar\.rb})
      end
    end

    # the scheduler job re-raises this one on purpose, so that the process manager restarts the process
    context 'when a calendar raises ActiveRecord::AdapterError' do
      before do
        allow(calendar_ical_sync_service)
          .to receive(:execute).with(calendar: broken_calendar).and_raise(ActiveRecord::AdapterError)
      end

      it 'lets the error through' do
        expect { described_class.sync }.to raise_error(ActiveRecord::AdapterError)
      end
    end
  end

  describe '#sync_ical' do
    subject(:calendar) do
      create(:calendar, ical_url: 'http://test/calendar1.ics', default: false)
    end

    let(:calendar_ical_sync_service) { Service::Calendar::Ical::Sync }

    before do
      allow(HostnameSafetyCheck).to receive(:validate!).and_return('1.2.3.4')
      stub_request(:get, 'http://test/calendar1.ics')
        .to_return(body: Rails.root.join('test/data/calendar/calendar1.ics').read)
      stub_request(:get, 'http://test/calendar2.ics')
        .to_return(body: Rails.root.join('test/data/calendar/calendar2.ics').read)
      travel_to Time.zone.parse('2017-08-24T01:04:44Z0')
    end

    it 'delegates to the sync service' do
      calendar # create and sync before counting calls
      allow(calendar_ical_sync_service).to receive(:execute)

      calendar.sync_ical

      expect(calendar_ical_sync_service).to have_received(:execute).with(calendar: calendar)
    end

    context 'without an iCal URL' do
      before do
        calendar # create and sync before counting calls
        allow(calendar_ical_sync_service).to receive(:execute)
      end

      it 'does not sync' do
        calendar.ical_url = nil

        expect(calendar.sync_ical).to be(false)
        expect(calendar_ical_sync_service).not_to have_received(:execute)
      end

      it 'does not sync for a blank URL either' do
        calendar.ical_url = ''

        expect(calendar.sync_ical).to be(false)
        expect(calendar_ical_sync_service).not_to have_received(:execute)
      end
    end

    context 'when the feed brings new events', :performs_jobs do
      before do
        calendar      # create and sync
        travel 1.year # reach the next recurrence, so the feed changes #public_holidays
        clear_jobs    # clear (speak: process) created jobs
      end

      it 'does create a background job for escalation rebuild' do
        expect { calendar.sync_ical }.to have_enqueued_job(TicketEscalationRebuildJob)
      end
    end

    context 'when the feed is unchanged', :performs_jobs do
      before do
        calendar   # create and sync
        clear_jobs # clear (speak: process) created jobs, dropping their ActiveJobLock
      end

      it 'does not create a background job for escalation rebuild' do
        expect { calendar.sync_ical } # a second sync right after calendar create
          .not_to have_enqueued_job(TicketEscalationRebuildJob)
      end
    end

    context 'when the iCal URL changes on save' do
      before { calendar.assign_attributes(ical_url: 'http://test/calendar2.ics') }

      it 'syncs on save' do
        expect { calendar.save }.to change(calendar, :public_holidays)
      end
    end
  end

  describe '#fetch_ical' do
    subject(:calendar) do
      create(:calendar, ical_url: 'http://test/calendar1.ics', default: false)
    end

    before do
      allow(HostnameSafetyCheck).to receive(:validate!).and_return('1.2.3.4')
      stub_request(:get, 'http://test/calendar1.ics')
        .to_return(body: Rails.root.join('test/data/calendar/calendar1.ics').read)
    end

    context 'when ical_url has not changed' do
      it 'does not sync on save' do
        calendar # force creation before setting expectation
        allow(Service::Calendar::Ical::Fetch).to receive(:execute).and_call_original

        calendar.update!(name: "#{calendar.name} updated")

        expect(Service::Calendar::Ical::Fetch).not_to have_received(:execute)
      end
    end

    context 'when ical_url has changed' do
      it 'leaves the saving to the enclosing save' do
        calendar # force creation before setting expectation
        allow(Service::Calendar::Ical::Sync).to receive(:execute)

        calendar.update!(ical_url: 'http://test/calendar2.ics')

        expect(Service::Calendar::Ical::Sync)
          .to have_received(:execute).with(calendar: calendar, save: false)
      end
    end

    context 'when ical_url is removed' do
      it 'drops the entries of the former feed' do
        expect { calendar.update!(ical_url: nil) }
          .to change { calendar.reload.public_holidays }.to({})
      end
    end
  end

  describe '#validate_hours' do
    context 'when business_hours are invalid' do

      it 'fails for hours ending at 00:00' do
        expect do
          create(:calendar,
                 business_hours: {
                   mon: {
                     active:     true,
                     timeframes: [['09:00', '00:00']]
                   },
                   tue: {
                     active:     true,
                     timeframes: [['09:00', '00:00']]
                   },
                   wed: {
                     active:     true,
                     timeframes: [['09:00', '00:00']]
                   },
                   thu: {
                     active:     true,
                     timeframes: [['09:00', '00:00']]
                   },
                   fri: {
                     active:     true,
                     timeframes: [['09:00', '00:00']]
                   },
                   sat: {
                     active:     false,
                     timeframes: [['09:00', '00:00']]
                   },
                   sun: {
                     active:     false,
                     timeframes: [['09:00', '00:00']]
                   }
                 })
        end.to raise_error(ActiveRecord::RecordInvalid, %r{nonsensical hours provided})
      end

      it 'fails for blank structure' do
        expect do
          create(:calendar,
                 business_hours: {})
        end.to raise_error(ActiveRecord::RecordInvalid, %r{There are no business hours configured.})
      end
    end
  end

  describe '#biz' do
    it 'overnight minutes are counted correctly' do
      travel_to Time.current.noon

      calendar = create(:calendar, '23:59/7')
      biz      = calendar.biz

      expect(biz.time(24, :hours).after(Time.current)).to eq 1.day.from_now
    end
  end

  describe '#business_hours_to_hash' do
    it 'returns a hash with all weekdays' do
      calendar = create(:calendar, '23:59/7')
      hash     = calendar.business_hours_to_hash

      expect(hash.keys).to eq %i[mon tue wed thu fri sat sun]
    end

    context 'with mocked hours' do
      let(:calendar) { create(:calendar, '23:59/7') }
      let(:result)   { calendar.business_hours_to_hash }

      before do
        calendar.business_hours = {
          day_1: { active: true, timeframes: [['09:00', '17:00']] },
          day_2: { active: true, timeframes: [['00:01', '02:00'], ['09:00', '17:00']] },
          day_3: { active: false, timeframes: [['09:00', '17:00']] }
        }
      end

      it { expect(result.keys).to eq %i[day_1 day_2] }
      it { expect(result[:day_1]).to eq({ '09:00' => '17:00' }) }
      it { expect(result[:day_2]).to eq({ '09:00' => '17:00', '00:01' => '02:00' }) }
    end
  end

  context 'when updated Calendar no longer matches Ticket', :performs_jobs do
    subject(:ticket) { create(:ticket, created_at: '2016-11-01 13:56:21 UTC', updated_at: '2016-11-01 13:56:21 UTC') }

    let(:calendar) do
      create(:calendar,
             business_hours:  {
               mon: {
                 active:     true,
                 timeframes: [ ['08:00', '20:00'] ]
               },
               tue: {
                 active:     true,
                 timeframes: [ ['08:00', '20:00'] ]
               },
               wed: {
                 active:     true,
                 timeframes: [ ['08:00', '20:00'] ]
               },
               thu: {
                 active:     true,
                 timeframes: [ ['08:00', '20:00'] ]
               },
               fri: {
                 active:     true,
                 timeframes: [ ['08:00', '20:00'] ]
               },
               sat: {
                 active:     false,
                 timeframes: [ ['08:00', '17:00'] ]
               },
               sun: {
                 active:     false,
                 timeframes: [ ['08:00', '17:00'] ]
               },
             },
             public_holidays: {
               '2016-11-01' => {
                 'active'  => true,
                 'summary' => 'test 1',
               },
             })
    end

    let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 60, response_time: 120, solution_time: nil) }

    before do
      queue_adapter.perform_enqueued_jobs = true
      queue_adapter.perform_enqueued_at_jobs = true

      sla
      ticket
      create(:'ticket/article', :inbound_web, ticket: ticket, created_at: '2016-11-01 13:56:21 UTC', updated_at: '2016-11-01 13:56:21 UTC')
      ticket.reload

      create(:'ticket/article', :outbound_email, ticket: ticket, created_at: '2016-11-07 13:26:36 UTC', updated_at: '2016-11-07 13:26:36 UTC')
      ticket.reload
    end

    it 'calculates escalation_at attributes' do

      expect(ticket.escalation_at).to be_nil
      expect(ticket.first_response_escalation_at).to be_nil
      expect(ticket.update_escalation_at).to be_nil
      expect(ticket.close_escalation_at).to be_nil

      # set sla's for timezone "Europe/Berlin" wintertime (+1), so UTC times are 3:00-18:00
      calendar.update!(
        business_hours:  {
          mon: {
            active:     true,
            timeframes: [ ['04:00', '20:00'] ]
          },
          tue: {
            active:     true,
            timeframes: [ ['04:00', '20:00'] ]
          },
          wed: {
            active:     true,
            timeframes: [ ['04:00', '20:00'] ]
          },
          thu: {
            active:     true,
            timeframes: [ ['04:00', '20:00'] ]
          },
          fri: {
            active:     true,
            timeframes: [ ['04:00', '20:00'] ]
          },
          sat: {
            active:     false,
            timeframes: [ ['04:00', '13:00'] ] # this changed from '17:00' => '13:00'
          },
          sun: {
            active:     false,
            timeframes: [ ['04:00', '17:00'] ]
          },
        },
        public_holidays: {
          '2016-11-01' => {
            'active'  => true,
            'summary' => 'test 1',
          },
        },
      )

      ticket.reload

      expect(ticket.escalation_at).to be_nil
      expect(ticket.first_response_escalation_at).to be_nil
      expect(ticket.update_escalation_at).to be_nil
      expect(ticket.close_escalation_at).to be_nil
    end

  end

  context 'when SLA relevant timezone holidays are configured' do

    let(:calendar) do
      create(:calendar,
             public_holidays: {
               '2015-09-22' => {
                 'active'  => true,
                 'summary' => 'test 1',
               },
               '2015-09-23' => {
                 'active'  => false,
                 'summary' => 'test 2',
               },
               '2015-09-24' => {
                 'removed' => false,
                 'summary' => 'test 3',
               },
             })
    end

    let(:sla) do
      create(:sla,
             calendar:            calendar,
             condition:           {},
             first_response_time: 120,
             response_time:       180,
             solution_time:       240)
    end

    before do
      sla
      ticket.reload
    end

    context 'when a Ticket is created in working hours but not affected by the configured holidays' do
      subject(:ticket) { create(:ticket, created_at: '2013-10-21 09:30:00 UTC', updated_at: '2013-10-21 09:30:00 UTC') }

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2013-10-21 11:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-10-21 11:30:00 UTC')
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-10-21 13:30:00 UTC')
      end
    end

    context 'when a Ticket is created before the working hours but not affected by the configured holidays' do
      subject(:ticket) { create(:ticket, created_at: '2013-10-21 05:30:00 UTC', updated_at: '2013-10-21 05:30:00 UTC') }

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2013-10-21 09:00:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-10-21 09:00:00 UTC')
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-10-21 11:00:00 UTC')
      end
    end

    context 'when a Ticket is created before the holidays but escalation should take place while holidays are' do
      subject(:ticket) { create(:ticket, created_at: '2015-09-21 14:30:00 UTC', updated_at: '2015-09-21 14:30:00 UTC') }

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2015-09-23 08:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2015-09-23 08:30:00 UTC')
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2015-09-23 10:30:00 UTC')
      end
    end
  end

  describe '.timezones' do
    it 'includes known zones' do
      expect(described_class.timezones.keys).to include('GMT', 'Europe/Berlin', 'Atlantic/Reykjavik')
    end
  end

  describe '#validate_ical_url_format' do
    it 'accepts a blank ical_url' do
      expect(build(:calendar, ical_url: nil)).to be_valid
    end

    it 'accepts an https URL' do
      expect(build(:calendar, ical_url: 'https://example.com/cal.ics')).to be_valid
    end

    it 'accepts an http URL' do
      expect(build(:calendar, ical_url: 'http://example.com/cal.ics')).to be_valid
    end

    it 'rejects a local file path' do
      calendar = build(:calendar, ical_url: '/etc/passwd')
      expect(calendar).not_to be_valid
      expect(calendar.errors[:ical_url]).to be_present
    end

    it 'rejects a plain string without scheme' do
      calendar = build(:calendar, ical_url: 'example.com/cal.ics')
      expect(calendar).not_to be_valid
      expect(calendar.errors[:ical_url]).to be_present
    end
  end
end
