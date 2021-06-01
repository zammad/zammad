# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Ticket::Article::HasTicketContactAttributesImpact' do

  describe '#update_ticket_article_attributes callback' do

    subject(:ticket) { create(:ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC') }

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

    before do
      sla
      ticket
    end

    context 'when inbound email Article is created' do

      it 'updates ticket article attributes' do
        article_inbound = create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC')

        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil
      end
    end

    context 'when outbound email Article is created in response to inbound email Article' do

      it 'updates ticket article attributes' do
        article_inbound = create(:'ticket/article', :inbound_email, ticket: ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC')
        ticket.reload

        article_outbound = create(:'ticket/article', :outbound_email, ticket: ticket, created_at: '2013-03-29 07:00:03 UTC', updated_at: '2013-03-29 07:00:03 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_agent_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.first_response_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.first_response_in_min).to eq(0)
        expect(ticket.first_response_diff_in_min).to eq(60)
        expect(ticket.close_at).to be_nil
      end
    end

    context 'when inbound phone Article is created' do

      it 'updates ticket article attributes' do
        article_inbound = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil
      end
    end

    context 'when outbound note Article is created in response to inbound phone Article' do

      it 'updates ticket article attributes' do
        article_inbound = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC')
        ticket.reload

        create(:'ticket/article', :outbound_note, ticket: ticket, created_at: '2013-03-28 23:52:00 UTC', updated_at: '2013-03-28 23:52:00 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil
      end
    end

    context 'when outbound phone Article is created after outbound note Article is created in response to inbound phone Article' do

      it 'updates ticket article attributes' do
        article_inbound = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2013-03-28 23:49:00 UTC', updated_at: '2013-03-28 23:49:00 UTC')
        ticket.reload

        create(:'ticket/article', :outbound_note, ticket: ticket, created_at: '2013-03-28 23:52:00 UTC', updated_at: '2013-03-28 23:52:00 UTC')
        ticket.reload

        article_outbound = create(:'ticket/article', :outbound_phone, ticket: ticket, created_at: '2013-03-28 23:55:00 UTC', updated_at: '2013-03-28 23:55:00 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_inbound.created_at.to_s)
        expect(ticket.last_contact_agent_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.first_response_at.to_s).to eq(article_outbound.created_at.to_s)
        expect(ticket.close_at).to be_nil
      end
    end

    context 'when inbound web Article is created' do
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

      let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 60, update_time: 120, solution_time: nil) }

      before do
        sla

        ticket
        create(:'ticket/article', :inbound_web, ticket: ticket, created_at: '2016-11-01 13:56:21 UTC', updated_at: '2016-11-01 13:56:21 UTC')

        ticket.reload
      end

      it 'calculates escalation_at attributes' do
        expect(ticket.escalation_at.gmtime.to_s).to eq('2016-11-02 08:00:00 UTC')
        expect(ticket.first_response_escalation_at.gmtime.to_s).to eq('2016-11-02 08:00:00 UTC')
        expect(ticket.update_escalation_at.gmtime.to_s).to eq('2016-11-02 09:00:00 UTC')
        expect(ticket.close_escalation_at).to be_nil
      end

      context 'when replied via outbound email' do

        before do
          create(:'ticket/article', :outbound_email, ticket: ticket, created_at: '2016-11-07 13:26:36 UTC', updated_at: '2016-11-07 13:26:36 UTC')
          ticket.reload
        end

        it 'calculates escalation_at attributes' do
          expect(ticket.escalation_at).to be_nil
          expect(ticket.first_response_escalation_at).to be_nil
          expect(ticket.update_escalation_at).to be_nil
          expect(ticket.close_escalation_at).to be_nil
        end
      end
    end

    context "when Setting 'ticket_last_contact_behaviour' is set to 'based_on_customer_reaction'" do

      subject(:ticket) { create(:ticket, created_at: '2018-05-01 13:56:21 UTC', updated_at: '2018-05-01 13:56:21 UTC') }

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

      let(:sla) { create(:sla, condition: {}, calendar: calendar, first_response_time: 60, update_time: 120, solution_time: nil) }

      before do
        Setting.set('ticket_last_contact_behaviour', 'based_on_customer_reaction')
        sla
      end

      it 'updates ticket article attributes' do
        ticket
        article = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2018-05-01 13:56:21 UTC', updated_at: '2018-05-01 13:56:21 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil

        article = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2018-05-01 14:56:21 UTC', updated_at: '2018-05-01 14:56:21 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil

        article_customer = create(:'ticket/article', :inbound_phone, ticket: ticket, created_at: '2018-05-01 15:56:21 UTC', updated_at: '2018-05-01 15:56:21 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_customer.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_customer.created_at.to_s)
        expect(ticket.last_contact_agent_at).to be_nil
        expect(ticket.first_response_at).to be_nil
        expect(ticket.close_at).to be_nil

        article_agent = create(:'ticket/article', :outbound_phone, ticket: ticket, created_at: '2018-05-01 16:56:21 UTC', updated_at: '2018-05-01 16:56:21 UTC')
        ticket.reload

        expect(ticket.last_contact_at.to_s).to eq(article_agent.created_at.to_s)
        expect(ticket.last_contact_customer_at.to_s).to eq(article_customer.created_at.to_s)
        expect(ticket.last_contact_agent_at.to_s).to eq(article_agent.created_at.to_s)
        expect(ticket.first_response_at.to_s).to eq(article_agent.created_at.to_s)
        expect(ticket.close_at).to be_nil
      end
    end

  end
end
