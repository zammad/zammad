# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_context 'with report examples' do
  before do |example|
    next if !example.metadata[:searchindex]

    ticket_1
    ticket_2
    ticket_3
    ticket_4
    ticket_5
    ticket_6
    ticket_7
    ticket_8
    ticket_9
    ticket_after_72h
    ticket_before_40d

    searchindex_model_reload([Ticket])
  end

  let(:group_1)  { Group.lookup(name: 'Users') }
  let(:group_2)  { create(:group) }
  let(:customer) { User.lookup(email: 'nicole.braun@zammad.org') }

  let(:ticket_1) do
    travel_to DateTime.new 2015, 10, 28, 9, 30
    ticket = create(:ticket,
                    group:         group_2,
                    customer:      customer,
                    state_name:    'new',
                    priority_name: '2 normal')

    ticket.tag_add('aaa', 1)
    ticket.tag_add('bbb', 1)
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)

    travel 5.hours

    ticket.update! group: group_1

    travel_back
    ticket
  end

  let(:ticket_2) do
    travel_to DateTime.new 2015, 10, 28, 9, 30, 1
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'new',
                    priority_name: '2 normal')

    ticket.tag_add('aaa', 1)
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)
    travel 5.hours - 1.second

    ticket.update! group: group_2

    travel_back
    ticket
  end

  let(:ticket_3) do
    travel_to DateTime.new 2015, 10, 28, 10, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'open',
                    priority_name: '3 high')
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)

    travel_back
    ticket
  end

  let(:ticket_4) do
    travel_to DateTime.new 2015, 10, 28, 10, 30, 1
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'closed',
                    priority_name: '2 normal',
                    close_at:      (1.hour - 1.second).from_now)
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)
    travel_back
    ticket
  end

  let(:ticket_5) do
    travel_to DateTime.new 2015, 10, 28, 11, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'closed',
                    priority_name: '3 high',
                    close_at:      10.minutes.from_now)

    ticket.tag_add('bbb', 1)
    create(:ticket_article,
           :outbound_email,
           ticket: ticket)

    ticket.update! state: Ticket::State.lookup(name: 'open')

    travel 3.hours

    travel_back
    ticket
  end

  let(:ticket_6) do
    travel_to DateTime.new 2015, 10, 31, 12, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'closed',
                    priority_name: '2 normal',
                    close_at:      5.minutes.from_now)
    create(:ticket_article,
           :outbound_email,
           ticket: ticket)

    travel_back
    ticket
  end

  let(:ticket_7) do
    travel_to DateTime.new 2015, 11, 1, 12, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'closed',
                    priority_name: '2 normal',
                    close_at:      Time.zone.now)
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)
    travel_back
    ticket
  end

  let(:ticket_8) do
    travel_to DateTime.new 2015, 11, 2, 12, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'merged',
                    priority_name: '2 normal',
                    close_at:      Time.zone.now)

    create(:ticket_article,
           :inbound_email,
           ticket: ticket)

    travel_back
    ticket
  end

  let(:ticket_9) do
    travel_to DateTime.new 2037, 11, 2, 12, 30
    ticket = create(:ticket,
                    group:         group_1,
                    customer:      customer,
                    state_name:    'merged',
                    priority_name: '2 normal',
                    close_at:      Time.zone.now)
    create(:ticket_article,
           :inbound_email,
           ticket: ticket)

    travel_back

    ticket
  end

  let(:ticket_after_72h) do
    travel 72.hours do
      ticket = create(:ticket,
                      group:         group_1,
                      customer:      customer,
                      state_name:    'closed',
                      priority_name: '2 normal',
                      close_at:      5.minutes.from_now)
      create(:ticket_article,
             :outbound_email,
             ticket: ticket)

      ticket
    end
  end

  let(:ticket_before_40d) do
    travel(-40.days) do
      ticket = create(:ticket,
                      group:         group_1,
                      customer:      customer,
                      state_name:    'closed',
                      priority_name: '2 normal',
                      close_at:      5.minutes.from_now)
      create(:ticket_article,
             :outbound_email,
             ticket: ticket)

      ticket
    end
  end

  matcher :match_tickets do
    match do
      if expected_tickets.blank?
        actual_ticket_ids.blank?
      else
        # GenericTime returns string ids :o
        actual_ticket_ids.map(&:to_i) == expected_tickets.map(&:id)
      end
    end

    def expected_tickets
      Array(expected)
    end

    def actual_ticket_ids
      actual[:ticket_ids]
    end
  end
end
