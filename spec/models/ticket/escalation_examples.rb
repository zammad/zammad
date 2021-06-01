# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Ticket::Escalation' do

  describe '#update_escalation_information callback' do

    context 'with standard incoming email with active SLA' do

      subject(:ticket) { create(:ticket, created_at: '2013-03-21 09:30:00 UTC', updated_at: '2013-03-21 09:30:00 UTC') }

      let(:calendar) do
        create(:calendar,
               business_hours: {
                 mon: {
                   active:     true,
                   timeframes: [ ['08:00', '18:00'] ]
                 },
                 tue: {
                   active:     true,
                   timeframes: [ ['08:00', '18:00'] ]
                 },
                 wed: {
                   active:     true,
                   timeframes: [ ['08:00', '18:00'] ]
                 },
                 thu: {
                   active:     true,
                   timeframes: [ ['08:00', '18:00'] ]
                 },
                 fri: {
                   active:     true,
                   timeframes: [ ['08:00', '18:00'] ]
                 },
                 sat: {
                   active:     false,
                   timeframes: [ ['08:00', '17:00'] ]
                 },
                 sun: {
                   active:     false,
                   timeframes: [ ['08:00', '17:00'] ]
                 },
               })
      end
      let(:sla) { create(:sla, calendar: calendar, first_response_time: 60, update_time: 120, solution_time: 180) }
      let(:article) { create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2013-03-21 09:30:00 UTC', updated_at: '2013-03-21 09:30:00 UTC') }

      before do
        sla
        ticket
        article
        ticket.reload
      end

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 10:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-03-21 10:30:00 UTC')
        expect(ticket.first_response_at).to be_nil
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil

        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
        expect(ticket.update_in_min).to be_nil
        expect(ticket.update_diff_in_min).to be_nil

        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil
      end

      context 'with first response time resolved by answer + state pending reminder' do
        before do
          ticket.update(state: Ticket::State.find_by(name: 'pending reminder'))
          create(:'ticket/article', :outbound_email, ticket: ticket, created_at: '2013-03-21 09:45:00 UTC', updated_at: '2013-03-21 09:45:00 UTC')
        end

        it 'does set first_response_diff_in_min' do
          expect(ticket.reload.first_response_diff_in_min).to eq(45)
        end
      end

      context 'with first response in time' do

        before do
          ticket.update!(
            first_response_at: '2013-03-21 10:00:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 10:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(30)
          expect(ticket.first_response_diff_in_min).to eq(30)

          expect(ticket.update_escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
          expect(ticket.update_in_min).to be_nil
          expect(ticket.update_diff_in_min).to be_nil

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time' do
        before do
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at.gmtime.to_s).to eq('2013-03-21 11:30:00 UTC')
          expect(ticket.update_in_min).to be_nil
          expect(ticket.update_diff_in_min).to be_nil

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time and update time in time' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time in time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 11:00:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.update_in_min).to eq(90)
          expect(ticket.update_diff_in_min).to eq(30)

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time and update time over time' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:00:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.update_in_min).to eq(150)
          expect(ticket.update_diff_in_min).to eq(-30)

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time and update time over time and customer reply' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_customer_at: '2013-03-21 12:05:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at.gmtime.to_s).to eq('2013-03-21 14:05:00 UTC')
          expect(ticket.update_in_min).to eq(150)
          expect(ticket.update_diff_in_min).to eq(-30)

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time and update time over time and customer reply with agent response' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_customer_at: '2013-03-21 12:05:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:10:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.update_in_min).to eq(150)
          expect(ticket.update_diff_in_min).to eq(-30)

          expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 12:30:00 UTC')
          expect(ticket.close_in_min).to be_nil
          expect(ticket.close_diff_in_min).to be_nil
        end
      end

      context 'with first response over time and update time over time and customer reply with agent response and closed in time' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_customer_at: '2013-03-21 12:05:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:10:00 UTC',
          )
          ticket.reload

          # set close time in time
          ticket.update!(
            close_at: '2013-03-21 11:30:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          # straight escalation after closing
          expect(ticket.escalation_at).to be_nil

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.update_in_min).to eq(150)
          expect(ticket.update_diff_in_min).to eq(-30)

          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(120)
          expect(ticket.close_diff_in_min).to eq(60)
        end
      end

      context 'with first response over time and update time over time and customer reply with agent response and closed over time' do
        before do
          # set first response over time
          ticket.update!(
            first_response_at: '2013-03-21 14:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:00:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_customer_at: '2013-03-21 12:05:00 UTC',
          )
          ticket.reload

          # set update time over time
          ticket.update!(
            last_contact_agent_at: '2013-03-21 12:10:00 UTC',
          )
          ticket.reload

          # set close time over time
          ticket.update!(
            close_at: '2013-03-21 13:00:00 UTC',
          )
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil

          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_at.gmtime.to_s).to eq('2013-03-21 14:00:00 UTC')
          expect(ticket.first_response_in_min).to eq(270)
          expect(ticket.first_response_diff_in_min).to eq(-210)

          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.update_in_min).to eq(150)
          expect(ticket.update_diff_in_min).to eq(-30)

          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(210)
          expect(ticket.close_diff_in_min).to eq(-30)
        end
      end

    end

    context 'when SLA no longer matches' do
      subject(:ticket) { create(:ticket, priority: priorty_matching, created_at: '2013-03-21 09:30:00 UTC', updated_at: '2013-03-21 09:30:00 UTC') }

      let(:priorty_matching) { create(:'ticket/priority') }
      let(:priorty_not_matching) { create(:'ticket/priority') }

      let(:calendar) do
        create(:calendar,
               business_hours: {
                 mon: {
                   active:     true,
                   timeframes: [ ['09:00', '17:00'] ]
                 },
                 tue: {
                   active:     true,
                   timeframes: [ ['09:00', '17:00'] ]
                 },
                 wed: {
                   active:     true,
                   timeframes: [ ['09:00', '17:00'] ]
                 },
                 thu: {
                   active:     true,
                   timeframes: [ ['09:00', '17:00'] ]
                 },
                 fri: {
                   active:     true,
                   timeframes: [ ['09:00', '17:00'] ]
                 },
                 sat: {
                   active:     false,
                   timeframes: [ ['08:00', '17:00'] ]
                 },
                 sun: {
                   active:     false,
                   timeframes: [ ['08:00', '17:00'] ]
                 },
               })
      end

      let(:sla) do
        create(:sla,
               calendar:            calendar,
               condition:           {
                 'ticket.priority_id' => {
                   operator: 'is',
                   value:    priorty_matching.id.to_s,
                 },
               },
               first_response_time: 60,
               update_time:         180,
               solution_time:       240)
      end

      it 'removes/resets the escalation attributes' do

        sla
        ticket.reload # read as: ticket; ticket.reload

        expect(ticket.escalation_at.gmtime.to_s).to eq('2013-03-21 10:30:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-03-21 10:30:00 UTC')
        expect(ticket.first_response_at).to be_nil
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil

        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.update_in_min).to be_nil
        expect(ticket.update_diff_in_min).to be_nil

        expect(ticket.close_escalation_at.gmtime.to_s).to eq('2013-03-21 13:30:00 UTC')
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil

        ticket.update!(priority: priorty_not_matching)
        ticket.reload

        expect(ticket.escalation_at).to be_nil
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.first_response_in_min).to be_nil
        expect(ticket.first_response_diff_in_min).to be_nil

        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.update_in_min).to be_nil
        expect(ticket.update_diff_in_min).to be_nil

        expect(ticket.close_escalation_at).to be_nil
        expect(ticket.close_in_min).to be_nil
        expect(ticket.close_diff_in_min).to be_nil
      end

    end

    context 'when Ticket state changes (escalation suspense)' do
      let(:calendar) do
        create(:calendar,
               business_hours: {
                 mon: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 tue: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 wed: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 thu: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 fri: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 sat: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
                 sun: {
                   active:     true,
                   timeframes: [ ['09:00', '18:00'] ]
                 },
               })
      end

      let(:sla) { create(:sla, calendar: calendar, first_response_time: 120, update_time: 180, solution_time: 250) }

      context 'when Ticket is reopened' do

        subject(:ticket) { create(:ticket, created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        before do
          # set ticket at 09:30 to pending
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o:                 ticket,
                 id_from:           Ticket::State.lookup(name: 'open').id,
                 id_to:             Ticket::State.lookup(name: 'pending reminder').id,
                 value_from:        'open',
                 value_to:          'pending reminder',
                 created_at:        '2013-06-04 09:30:00 UTC',
                 updated_at:        '2013-06-04 09:30:00 UTC',)

          # set ticket at 09:45 to open
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o:                 ticket,
                 id_from:           Ticket::State.lookup(name: 'pending reminder').id,
                 id_to:             Ticket::State.lookup(name: 'open').id,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 09:45:00 UTC',
                 updated_at:        '2013-06-04 09:45:00 UTC',)

          # set ticket at 10:00 to closed
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o:                 ticket,
                 id_from:           Ticket::State.lookup(name: 'open').id,
                 id_to:             Ticket::State.lookup(name: 'closed').id,
                 value_from:        'open',
                 value_to:          'closed',
                 created_at:        '2013-06-04 10:00:00 UTC',
                 updated_at:        '2013-06-04 10:00:00 UTC',)

          # set ticket at 10:30 to open
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o:                 ticket,
                 id_from:           Ticket::State.lookup(name: 'closed').id,
                 id_to:             Ticket::State.lookup(name: 'open').id,
                 value_from:        'closed',
                 value_to:          'open',
                 created_at:        '2013-06-04 10:30:00 UTC',
                 updated_at:        '2013-06-04 10:30:00 UTC',)

          sla
          ticket.escalation_calculation
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-06-04 11:45:00 UTC')
          expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-06-04 11:45:00 UTC')
          expect(ticket.first_response_in_min).to be_nil
          expect(ticket.first_response_diff_in_min).to be_nil
        end

      end

      context 'when Ticket transitions from pending to open' do

        subject(:ticket) { create(:ticket, created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        before do
          sla

          # set ticket at 10:00 to pending
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_from:           Ticket::State.lookup(name: 'open').id,
                 id_to:             Ticket::State.lookup(name: 'pending reminder').id,
                 value_from:        'open',
                 value_to:          'pending reminder',
                 created_at:        '2013-06-04 10:00:00 UTC',
                 updated_at:        '2013-06-04 10:00:00 UTC',)

          # set ticket at 15:00 to open
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_from:           Ticket::State.lookup(name: 'pending reminder').id,
                 id_to:             Ticket::State.lookup(name: 'open').id,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 15:00:00 UTC',
                 updated_at:        '2013-06-04 15:00:00 UTC',)

          ticket.escalation_calculation
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at.gmtime.to_s).to eq('2013-06-05 07:00:00 UTC')
          expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2013-06-05 07:00:00 UTC')
          expect(ticket.first_response_in_min).to be_nil
          expect(ticket.first_response_diff_in_min).to be_nil
        end
      end

      context 'when Ticket transitions from open to pending to open, response and close' do

        subject(:ticket) { create(:ticket, created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 7:00-16:00
        let(:calendar) do
          create(:calendar,
                 business_hours: {
                   mon: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   tue: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   wed: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   thu: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   fri: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sat: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sun: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                 })
        end

        let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 120, update_time: 180, solution_time: 250) }

        before do
          sla

          # set ticket at 10:00 to pending
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             3,
                 id_from:           2,
                 value_from:        'open',
                 value_to:          'pending reminder',
                 created_at:        '2013-06-04 10:00:00 UTC',
                 updated_at:        '2013-06-04 10:00:00 UTC',)

          # set ticket at 10:30 to open
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             2,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 10:30:00 UTC',
                 updated_at:        '2013-06-04 10:30:00 UTC')

          # set update time
          ticket.update!(
            last_contact_agent_at: '2013-06-04 10:15:00 UTC',
          )

          # set first response time
          ticket.update!(
            first_response_at: '2013-06-04 10:45:00 UTC',
          )

          # set ticket from 11:30 to closed
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             3,
                 id_from:           2,
                 value_from:        'open',
                 value_to:          'closed',
                 created_at:        '2013-06-04 12:00:00 UTC',
                 updated_at:        '2013-06-04 12:00:00 UTC')

          ticket.update!(
            close_at: '2013-06-04 12:00:00 UTC',
          )

          ticket.escalation_calculation
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_in_min).to eq(75)
          expect(ticket.first_response_diff_in_min).to eq(45)
          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(150)
          expect(ticket.close_diff_in_min).to eq(100)
        end

      end

      context 'when Ticket is created in state pending and closed without reopen or state change' do

        subject(:ticket) { create(:ticket, state: Ticket::State.lookup(name: 'pending reminder'), created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 7:00-16:00
        let(:calendar) do
          create(:calendar,
                 business_hours: {
                   mon: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   tue: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   wed: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   thu: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   fri: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sat: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sun: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                 })
        end

        let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 120, update_time: 180, solution_time: 240) }

        before do
          sla

          # set ticket from 11:30 to closed
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             4,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'closed',
                 created_at:        '2013-06-04 12:00:00 UTC',
                 updated_at:        '2013-06-04 12:00:00 UTC',)

          ticket.update!(
            close_at: '2013-06-04 12:00:00 UTC',
          )

          ticket.escalation_calculation

          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_in_min).to be_nil
          expect(ticket.first_response_diff_in_min).to be_nil
          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(0)
          expect(ticket.close_diff_in_min).to eq(240)
        end

      end

      context 'when Ticket created in state pending, changed state to openen, back to pending and closed' do
        subject(:ticket) { create(:ticket, state: Ticket::State.lookup(name: 'pending reminder'), created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 7:00-16:00
        let(:calendar) do
          create(:calendar,
                 business_hours: {
                   mon: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   tue: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   wed: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   thu: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   fri: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sat: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sun: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                 })
        end

        let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 120, update_time: 180, solution_time: 240) }

        before do
          sla

          # state change to open 10:30
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             2,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 10:30:00 UTC',
                 updated_at:        '2013-06-04 10:30:00 UTC',)

          # state change to pending 11:00
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             3,
                 id_from:           2,
                 value_from:        'open',
                 value_to:          'pending reminder',
                 created_at:        '2013-06-04 11:00:00 UTC',
                 updated_at:        '2013-06-04 11:00:00 UTC',)

          # set ticket from 12:00 to closed
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             4,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'closed',
                 created_at:        '2013-06-04 12:00:00 UTC',
                 updated_at:        '2013-06-04 12:00:00 UTC',)
          ticket.update!(
            close_at: '2013-06-04 12:00:00 UTC',
          )

          ticket.escalation_calculation
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_in_min).to be_nil
          expect(ticket.first_response_diff_in_min).to be_nil
          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(30)
          expect(ticket.close_diff_in_min).to eq(210)
        end

      end

      context 'when Test Ticket created in state pending, changed state to openen, back to pending and back to open then - close ticket' do
        subject(:ticket) { create(:ticket, state: Ticket::State.lookup(name: 'pending reminder'), created_at: '2013-06-04 09:00:00 UTC', updated_at: '2013-06-04 09:00:00 UTC') }

        # set sla's for timezone "Europe/Berlin" summertime (+2), so UTC times are 7:00-16:00
        let(:calendar) do
          create(:calendar,
                 business_hours: {
                   mon: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   tue: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   wed: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   thu: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   fri: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sat: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                   sun: {
                     active:     true,
                     timeframes: [ ['09:00', '18:00'] ]
                   },
                 })
        end

        let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 120, update_time: 180, solution_time: 240) }

        before do
          sla

          # state change to open from pending
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             2,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 10:30:00 UTC',
                 updated_at:        '2013-06-04 10:30:00 UTC',)

          # state change to pending from open 11:00
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             3,
                 id_from:           2,
                 value_from:        'open',
                 value_to:          'pending reminder',
                 created_at:        '2013-06-04 11:00:00 UTC',
                 updated_at:        '2013-06-04 11:00:00 UTC',)

          # state change to open 11:30
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             2,
                 id_from:           3,
                 value_from:        'pending reminder',
                 value_to:          'open',
                 created_at:        '2013-06-04 11:30:00 UTC',
                 updated_at:        '2013-06-04 11:30:00 UTC',)

          # set ticket from open to closed 12:00
          create(:history,
                 history_type:      'updated',
                 history_attribute: 'state',
                 o_id:              ticket.id,
                 id_to:             4,
                 id_from:           3,
                 value_from:        'open',
                 value_to:          'closed',
                 created_at:        '2013-06-04 12:00:00 UTC',
                 updated_at:        '2013-06-04 12:00:00 UTC',)
          ticket.update!(
            close_at: '2013-06-04 12:00:00 UTC',
          )

          ticket.escalation_calculation
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.first_response_in_min).to be_nil
          expect(ticket.first_response_diff_in_min).to be_nil
          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.close_escalation_at).to be_nil
          expect(ticket.close_in_min).to eq(60)
          expect(ticket.close_diff_in_min).to eq(180)
        end
      end

    end

    context 'when SLA has Calendar with holidays' do
      subject(:ticket) { create(:ticket, created_at: '2016-11-01 13:56:21 UTC', updated_at: '2016-11-01 13:56:21 UTC') }

      # set sla's for timezone "Europe/Berlin" wintertime (+1), so UTC times are 7:00-18:00
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

      let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 120, update_time: 1200, solution_time: nil) }

      before do
        sla
        ticket
      end

      it 'calculates escalation_at attributes' do
        create(:'ticket/article', :inbound_web, ticket: ticket, created_at: '2016-11-01 13:56:21 UTC', updated_at: '2016-11-01 13:56:21 UTC')
        ticket.reload

        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-11-02 09:00:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2016-11-02 09:00:00 UTC')
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-11-03 15:00:00 UTC')
        expect(ticket.close_escalation_at).to be_nil

        ticket.update!(
          state:        Ticket::State.lookup(name: 'pending reminder'),
          pending_time: '2016-11-10 07:00:00 UTC',
          updated_at:   '2016-11-01 15:25:40 UTC',
        )

        create(:'ticket/article', :outbound_email, ticket: ticket, created_at: '2016-11-01 15:25:40 UTC', updated_at: '2016-11-01 15:25:40 UTC')
        ticket.reload

        expect(ticket.escalation_at).to be_nil
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at).to be_nil

        ticket.update!(
          state:      Ticket::State.lookup(name: 'open'),
          updated_at: '2016-11-01 15:59:14 UTC',
        )

        create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2016-11-01 15:59:14 UTC', updated_at: '2016-11-01 15:59:14 UTC')
        ticket.reload

        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-11-03 15:00:00 UTC')
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-11-03 15:00:00 UTC')
        expect(ticket.close_escalation_at).to be_nil

        ticket.update!(
          state:        Ticket::State.lookup(name: 'pending reminder'),
          pending_time: '2016-11-18 07:00:00 UTC',
          updated_at:   '2016-11-01 15:59:58 UTC',
        )
        ticket.reload

        expect(ticket.escalation_at).to be_nil
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.update_escalation_at).to be_nil
        expect(ticket.close_escalation_at).to be_nil

        ticket.update!(
          state:      Ticket::State.lookup(name: 'open'),
          updated_at: '2016-11-07 13:26:36 UTC',
        )

        create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2016-11-07 13:26:36 UTC', updated_at: '2016-11-07 13:26:36 UTC')
        ticket.reload

        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-11-09 09:26:00 UTC')
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-11-09 09:26:00 UTC')
        expect(ticket.close_escalation_at).to be_nil

        create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2016-11-07 14:26:36 UTC', updated_at: '2016-11-07 14:26:36 UTC')
        ticket.reload

        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-11-09 09:26:00 UTC')
        expect(ticket.first_response_escalation_at).to be_nil
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-11-09 09:26:00 UTC')
        expect(ticket.close_escalation_at).to be_nil
      end
    end
  end
end
