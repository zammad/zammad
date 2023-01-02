# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CalendarSubscriptions, :aggregate_failures do
  # Set second fraction to zero for easier comparsion.
  def dt_now
    now = DateTime.now
    DateTime.new(now.year, now.month, now.day, now.hour, now.minute, now.second, 0)
  end

  let(:groups) { create_list(:group, 2) }
  let(:agents) do
    [
      create(:agent, groups: [groups.first]),
      create(:agent, groups: [groups.second])
    ]
  end
  let(:tickets) do
    tickets = [
      create(:ticket,
             group: groups.first,
             owner: agents.first),
      create(:ticket,
             group:        groups.first,
             owner:        agents.first,
             state:        Ticket::State.lookup(name: 'pending reminder'),
             pending_time: dt_now + 2.days),
      create(:ticket,
             group: groups.first,
             owner: agents.first),

      create(:ticket,
             group: groups.second,
             owner: agents.second),
      create(:ticket,
             group:        groups.second,
             owner:        agents.second,
             state:        Ticket::State.lookup(name: 'pending reminder'),
             pending_time: dt_now + 2.days),
      create(:ticket,
             group: groups.second,
             owner: agents.second),

      create(:ticket,
             group: groups.first,
             owner: User.find(1)),
      create(:ticket,
             group:        groups.first,
             owner:        User.find(1),
             state:        Ticket::State.lookup(name: 'pending reminder'),
             pending_time: dt_now + 2.days),

      create(:ticket,
             group: groups.first,
             owner: User.find(1)),

      create(:ticket,
             group: groups.second,
             owner: User.find(1)),

      create(:ticket,
             group:        groups.second,
             owner:        User.find(1),
             state:        Ticket::State.lookup(name: 'pending reminder'),
             pending_time: dt_now + 2.days),

      create(:ticket,
             group: groups.second,
             owner: User.find(1))
    ]
    # set escalation_at manually, clear cache to have correct content later
    [2, 5, 8, 11].each do |index|
      tickets[index].update_columns(escalation_at: dt_now + 2.weeks)
    end
    Rails.cache.clear

    tickets
  end
  let(:ical)      { described_class.new(agent).all }
  let(:calendars) { Icalendar::Calendar.parse(ical) }

  # https://github.com/zammad/zammad/issues/3989
  # https://datatracker.ietf.org/doc/html/rfc5545#section-3.2.19
  shared_examples 'verify ical' do
    it 'has timezone information' do
      vtimezone = $1 if ical =~ %r{(BEGIN:VTIMEZONE(?:.|\n)+END:VTIMEZONE)}
      expect(vtimezone).to be_present

      tzid = $1 if vtimezone =~ %r{TZID:(.+)}
      expect(tzid).to match(Setting.get('timezone_default_sanitized'))
    end
  end

  shared_examples 'verify calendar' do |params|
    it "has #{params[:count]} calendar with #{params[:events]} events" do
      expect(calendars.count).to be(params[:count])
      expect(calendars.first.events.count).to be(params[:events])
      expect(calendars.first.has_timezone?).to be true
    end
  end

  def event_to_ticket(event)
    Ticket.find_by(number: event.description.to_s[2..])
  end

  shared_examples 'verify events' do |params|
    it 'has ticket related events' do
      calendars.first.events.each do |event|
        ticket = event_to_ticket(event)

        expect(event.description.to_s).to match("T##{ticket.number}")
        expect(event.summary.to_s).to match(ticket.title)

        if !event.summary.to_s.match?(%r{^new})
          expect(event.has_alarm?).to be params[:alarm]
        end
      end
    end
  end

  def verify_timestamp(dtstart, dtend, tstart)
    expect(dtstart).to match(tstart)
    expect(dtend).to match(tstart)
  end

  def verify_offset(dtstart, dtend, tstart)
    time_zone = Setting.get('timezone_default_sanitized')
    tz = ActiveSupport::TimeZone.find_tzinfo(time_zone)

    expect(dtstart.utc_offset).to match(tz.utc_to_local(tstart).utc_offset)
    expect(dtend.utc_offset).to match(tz.utc_to_local(tstart).utc_offset)
  end

  # https://github.com/zammad/zammad/issues/4307
  shared_examples 'verify timestamps' do
    it 'event timestamps match related ticket timestamps' do

      calendars.first.events.each do |event|
        ticket = event_to_ticket(event)

        dtstart = event.dtstart
        dtend = event.dtend

        case event.summary.to_s
        when %r{new}
          tstart = ticket.updated_at

          expect(dtstart.strftime('%Y-%m-%d')).to match(ticket.updated_at.strftime('%Y-%m-%d'))
          expect(dtend.strftime('%Y-%m-%d')).to match(ticket.updated_at.strftime('%Y-%m-%d'))
          verify_offset(dtstart, dtend, tstart)

          next
        when %r{pending reminder}
          tstart = ticket.pending_time
        when %r{ticket escalation}
          tstart = ticket.escalation_at
        end

        verify_timestamp(dtstart, dtend, tstart)
        verify_offset(dtstart, dtend, tstart)
      end
    end
  end

  describe 'with subscriber agent in first group' do
    let(:agent) { agents.first }

    context 'with default subscriptions' do
      before do
        tickets
        calendars
      end

      include_examples 'verify ical'
      include_examples 'verify calendar', {
        count:  1,
        events: 4,
      }
      include_examples 'verify events', { alarm: false }
      include_examples 'verify timestamps'
    end

    context 'with specific subscriptions' do
      before do
        agent.preferences[:calendar_subscriptions] ||= {}

        agent.preferences[:calendar_subscriptions][:tickets] = {
          escalation: {
            own:          true,
            not_assigned: true,
          },
          new_open:   {
            own:          true,
            not_assigned: true,
          },
          pending:    {
            own:          true,
            not_assigned: true,
          },
          alarm:      true,
        }
        agent.save!

        tickets
        calendars
      end

      include_examples 'verify ical'
      include_examples 'verify calendar', {
        count:  1,
        events: 8,
      }
      include_examples 'verify events', { alarm: true }
      include_examples 'verify timestamps'
    end
  end

  describe 'with subscriber agent in second group' do
    let(:agent) { agents.second }

    context 'with default subscriptions' do
      before do
        Setting.set('timezone_default', 'Europe/Berlin')
        tickets
        calendars
      end

      include_examples 'verify ical', {
        count:  1,
        events: 4,
      }
      include_examples 'verify events', { alarm: false }
      include_examples 'verify timestamps'
    end

    context 'with specific subscriptions' do
      before do
        Setting.set('timezone_default', 'Europe/Berlin')

        agent.preferences[:calendar_subscriptions] ||= {}

        agent.preferences[:calendar_subscriptions][:tickets] = {
          escalation: {
            own:          true,
            not_assigned: true,
          },
          new_open:   {
            own:          true,
            not_assigned: true,
          },
          pending:    {
            own:          true,
            not_assigned: true,
          },
          alarm:      false,
        }
        agent.save!

        tickets
        calendars
      end

      include_examples 'verify ical'
      include_examples 'verify calendar', {
        count:  1,
        events: 8,
      }
      include_examples 'verify events', { alarm: false }
      include_examples 'verify timestamps'
    end
  end
end
