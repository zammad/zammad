# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Calendar, type: :model do
  subject(:calendar) { create(:calendar) }

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

    describe '#public_holidays' do
      subject(:calendar) do
        create(:calendar, ical_url: Rails.root.join('test/data/calendar/calendar1.ics'))
      end

      before { travel_to Time.zone.parse('2017-08-24T01:04:44Z0') }

      context 'on creation' do
        it 'is computed from iCal event data (implicitly via #sync), from one year before to three years after' do
          expect(calendar.public_holidays).to eq(
            '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
          )
        end

        context 'with one-time and n-time (recurring) events' do
          subject(:calendar) do
            create(:calendar, ical_url: Rails.root.join('test/data/calendar/calendar3.ics'))
          end

          it 'accurately computes/imports events' do
            expect(calendar.public_holidays).to eq(
              '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-28' => { 'active' => true, 'summary' => 'day5', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-01-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-02-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-03-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-04-26' => { 'active' => true, 'summary' => 'day3', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            )
          end
        end
      end
    end
  end

  describe '#sync' do
    subject(:calendar) do
      create(:calendar, ical_url: Rails.root.join('test/data/calendar/calendar1.ics'), default: false)
    end

    before { travel_to Time.zone.parse('2017-08-24T01:04:44Z0') }

    context 'when called explicitly after creation' do
      it 'writes #public_holidays to the cache (valid for 1 day)' do
        expect(Rails.cache.read("CalendarIcal::#{calendar.id}")).to be_nil

        expect { calendar.sync }
          .to change { Rails.cache.read("CalendarIcal::#{calendar.id}") }
          .to(calendar.attributes.slice('public_holidays', 'ical_url').symbolize_keys)
      end

      context 'and neither current date nor iCal URL have changed' do
        it 'is idempotent' do
          expect { calendar.sync }
            .not_to change(calendar, :public_holidays)
        end

        it 'does not create a background job for escalation rebuild' do
          calendar # create and sync (1 inital background job is created)
          expect { calendar.sync } # a second sync right after calendar create
            .to not_change { Delayed::Job.count }
        end
      end

      context 'and current date has changed but neither public_holidays nor iCal URL have changed (past cache expiry)' do
        before do
          calendar  # create and sync
          travel 2.days
        end

        it 'is idempotent' do
          expect { calendar.sync }
            .not_to change(calendar, :public_holidays)
        end

        it 'does not create a background job for escalation rebuild' do
          expect { calendar.sync }
            .not_to change(Delayed::Job, :count)
        end
      end

      context 'and current date has changed (past cache expiry)', performs_jobs: true do
        before do
          calendar  # create and sync
          clear_jobs # clear (speak: process) created jobs
          travel 1.year
        end

        it 'appends newly computed event data to #public_holidays' do
          expect { calendar.sync }.to change(calendar, :public_holidays).to(
            '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            '2020-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
          )
        end

        it 'does create a background job for escalation rebuild' do
          expect { calendar.sync }.to have_enqueued_job(TicketEscalationRebuildJob)
        end
      end

      context 'and iCal URL has changed' do
        before { calendar.assign_attributes(ical_url: Rails.root.join('test/data/calendar/calendar2.ics')) }

        it 'replaces #public_holidays with event data computed from new iCal URL' do
          expect { calendar.save }
            .to change(calendar, :public_holidays).to(
              '2016-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2016-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2017-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2018-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-24' => { 'active' => true, 'summary' => 'Christmas1', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
              '2019-12-25' => { 'active' => true, 'summary' => 'Christmas2', 'feed' => Digest::MD5.hexdigest(calendar.ical_url) },
            )
        end
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
end
