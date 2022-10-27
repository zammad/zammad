# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CalendarSubscriptions, :aggregate_failures do
  let(:groups) { create_list(:group, 2) }
  let(:agents) do
    [
      create(:agent, groups: [groups.first]),
      create(:agent, groups: [groups.second])
    ]
  end
  let(:tickets) do
    travel_to DateTime.now - 3.months

    tickets = [
      create(:ticket,
             group: groups.first,
             owner: agents.first),
      create(:ticket,
             group:        groups.first,
             owner:        agents.first,
             state:        Ticket::State.lookup(name: 'pending reminder'),
             pending_time: DateTime.now + 2.days),
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
             pending_time: DateTime.now + 2.days),
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
             pending_time: DateTime.now + 2.days),

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
             pending_time: DateTime.now + 2.days),

      create(:ticket,
             group: groups.second,
             owner: User.find(1))
    ]
    # set escalation_at manually, clear cache to have correct content later
    [2, 5, 8, 11].each do |index|
      tickets[index].update_columns(escalation_at: DateTime.now + 2.weeks)
    end
    Rails.cache.clear

    travel_back
    tickets
  end
  let(:ical) { described_class.new(agent).all }
  let(:calendars) do
    Icalendar::Calendar.parse(ical).each do |calendar|
      calendar.events.sort_by!(&:description)
    end
  end

  # https://github.com/zammad/zammad/issues/3989
  # https://datatracker.ietf.org/doc/html/rfc5545#section-3.2.19
  shared_examples 'verify ical' do
    it 'has timezone information' do
      vtimezone = $1 if ical =~ %r{(BEGIN:VTIMEZONE(?:.|\n)+END:VTIMEZONE)}
      expect(vtimezone).to be_present

      tzid = $1 if vtimezone =~ %r{TZID:(.+)}
      expect(tzid).to match(Setting.get('timezone_default').presence || 'UTC')
    end
  end

  shared_examples 'verify calendar' do |params|
    it "has #{params[:count]} calendar with #{params[:events]} events" do
      expect(calendars.count).to be(params[:count])
      expect(calendars.first.events.count).to be(params[:events])
      expect(calendars.first.has_timezone?).to be true
    end
  end

  shared_examples 'verify events' do |params|
    it 'has ticket related events' do
      params[:expectations].each do |expected|
        event = calendars.first.events[expected[:event_id]]
        ticket = tickets[expected[:ticket_id]]

        expect(event.dtstart.strftime('%Y-%m-%d')).to match(Time.zone.today.to_s)
        expect(event.description.to_s).to match("T##{ticket.number}")
        expect(event.summary).to match(ticket.title)
        expect(event.has_alarm?).to be expected[:alarm] || false
      end
    end
  end

  describe 'with subscriber agent in first group' do
    context 'with default subscriptions' do
      before do
        tickets
        calendars
      end

      let(:agent) { agents.first }

      include_examples 'verify ical'

      include_examples 'verify calendar', {
        count:  1,
        events: 4,
      }

      include_examples 'verify events', {
        expectations: [
          { event_id: 0, ticket_id: 0 },
          { event_id: 1, ticket_id: 1 },
          { event_id: 2, ticket_id: 2 },
          { event_id: 3, ticket_id: 2 }
        ]
      }
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

      let(:agent) { agents.first }

      include_examples 'verify ical'

      include_examples 'verify calendar', {
        count:  1,
        events: 8,
      }

      include_examples 'verify events', {
        expectations: [
          { event_id: 0, ticket_id: 0 },
          { event_id: 1, ticket_id: 1, alarm: true },
          { event_id: 2, ticket_id: 2 },
          { event_id: 3, ticket_id: 2, alarm: true },
          { event_id: 4, ticket_id: 6 },
          { event_id: 5, ticket_id: 7, alarm: true },
          { event_id: 6, ticket_id: 8 },
          { event_id: 7, ticket_id: 8, alarm: true }
        ]
      }
    end
  end

  describe 'with subscriber agent in second group' do
    context 'with default subscriptions' do
      before do
        Setting.set('timezone_default', 'Europe/Berlin')
        tickets
        calendars
      end

      let(:agent) { agents.second }

      include_examples 'verify ical'

      include_examples 'verify calendar', {
        count:  1,
        events: 4,
      }

      include_examples 'verify events', {
        expectations: [
          { event_id: 0, ticket_id: 3 },
          { event_id: 1, ticket_id: 4 },
          { event_id: 2, ticket_id: 5 },
          { event_id: 3, ticket_id: 5 }
        ]
      }
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

      let(:agent) { agents.second }

      include_examples 'verify ical'

      include_examples 'verify calendar', {
        count:  1,
        events: 8,
      }

      include_examples 'verify events', {
        expectations: [
          { event_id: 0, ticket_id: 3 },
          { event_id: 1, ticket_id: 4 },
          { event_id: 2, ticket_id: 5 },
          { event_id: 3, ticket_id: 5 },
          { event_id: 4, ticket_id: 9 },
          { event_id: 5, ticket_id: 10 },
          { event_id: 6, ticket_id: 11 },
          { event_id: 7, ticket_id: 11 },
        ]
      }
    end
  end
end
