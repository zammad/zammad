# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::Update::Bulk, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketUpdateBulk($selector: TicketBulkSelectorInput!, $perform: TicketBulkPerformInput!) {
        ticketUpdateBulk(selector: $selector, perform: $perform) {
          async
          total
          failedCount
          inaccessibleTicketIds
          invalidTicketIds
        }
      }
    QUERY
  end
  let(:agent)         { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer)      { create(:customer) }
  let(:user)          { agent }
  let(:group)         { agent.groups.first }
  let(:ticket1)       { create(:ticket, title: 'Ticket 1', group: agent.groups.first, customer: customer) }
  let(:ticket2)       { create(:ticket, title: 'Ticket 2', group: agent.groups.first, customer: customer) }
  let(:input_payload) { { title: 'Ticket Bulk Update Mutation Test' } }
  let(:selector)      { { entityIds: [gql.id(ticket1), gql.id(ticket2)] } }
  let(:perform)       { { input: input_payload } }
  let(:variables)     { { selector:, perform: } }

  let(:expected_response) do
    { async: false, total: 2, failedCount: nil, inaccessibleTicketIds: nil, invalidTicketIds: nil }
      .with_indifferent_access
  end

  context 'when updating a ticket' do

    context 'with an agent', authenticated_as: :agent do
      let(:expected_response) do
        { async: false, total: 2, failedCount: 0, inaccessibleTicketIds: [], invalidTicketIds: [] }
          .with_indifferent_access
      end

      it 'updates the attributes' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq(expected_response)
        expect(ticket1.reload).to have_attributes(title: 'Ticket Bulk Update Mutation Test')
      end

      context 'when a ticket update fails' do
        before do
          allow_any_instance_of(Service::Ticket::Update).to receive(:execute).and_wrap_original do |m, *args, **kwargs|
            if kwargs[:ticket].title == 'Ticket 2'
              raise ActiveRecord::RecordNotSaved.new('test failure during update of second ticket', ticket2)
            end

            m.call(*args, **kwargs)
          end
        end

        let(:expected_response) do
          { async: false, total: 2, failedCount: 1, inaccessibleTicketIds: [], invalidTicketIds: [gql.id(ticket2)] }
            .with_indifferent_access
        end

        it 'rolls back the affected ticket only' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(expected_response)
          expect(ticket1.reload).to have_attributes(title: 'Ticket Bulk Update Mutation Test')
          expect(ticket2.reload).to have_attributes(title: 'Ticket 2')
        end
      end

      context 'when permission is denied for one ticket' do
        before do
          allow_any_instance_of(TicketPolicy).to receive(:agent_update_access?).and_wrap_original do |m, *args|
            ticket = m.receiver.record
            if ticket.title == 'Ticket 2'
              false
            else
              m.call(*args)
            end
          end
        end

        let(:expected_response) do
          { async: false, total: 2, failedCount: 1, inaccessibleTicketIds: [gql.id(ticket2)], invalidTicketIds: [] }
            .with_indifferent_access
        end

        it 'categorizes permission failures as inaccessible' do
          gql.execute(query, variables: variables)
          expect(gql.result.data).to eq(expected_response)
          expect(ticket1.reload).to have_attributes(title: 'Ticket Bulk Update Mutation Test')
          expect(ticket2.reload).to have_attributes(title: 'Ticket 2')
        end
      end

      context 'with a macro' do
        let(:new_title) { Faker::Lorem.word }
        let(:macro)     { create(:macro, perform: { 'ticket.title' => { 'value' => new_title } }) }

        let(:variables) do
          {
            selector: {
              entityIds: [gql.id(ticket1), gql.id(ticket2)],
            },
            perform:  {
              input:   input_payload,
              macroId: gql.id(macro)
            }
          }
        end

        it 'applies the macro' do
          gql.execute(query, variables:)

          expect(ticket1.reload).to have_attributes(title: new_title)
        end

        context 'when only macroId is provided (no input)' do
          let(:variables) do
            {
              selector: {
                entityIds: [gql.id(ticket1), gql.id(ticket2)],
              },
              perform:  {
                macroId: gql.id(macro)
              }
            }
          end

          it 'applies the macro without crashing' do
            gql.execute(query, variables:)

            expect(ticket1.reload).to have_attributes(title: new_title)
            expect(ticket2.reload).to have_attributes(title: new_title)
          end
        end
      end

      context 'with an article payload' do
        let(:input_payload) do
          {
            article: {
              body: 'bulk note body',
              type: 'note',
            }
          }
        end

        it 'creates a note on every selected ticket' do
          expect { gql.execute(query, variables:) }
            .to change(Ticket::Article, :count).by(2)

          expect(ticket1.reload.articles.last.body).to eq('bulk note body')
          expect(ticket1.articles.last.type.name).to eq('note')
          expect(ticket2.reload.articles.last.body).to eq('bulk note body')
          expect(ticket2.articles.last.type.name).to eq('note')
        end

        context 'when dispatched asynchronously', performs_jobs: true do
          before do
            stub_const('Service::Ticket::Bulk::DispatchUpdate::BACKGROUND_UPDATE_THRESHOLD', 1)
          end

          it 'creates a note on every selected ticket' do
            expect do
              perform_enqueued_jobs do
                gql.execute(query, variables:)
                expect(gql.result.data).to include(async: true, total: 2)
              end
            end.to change(Ticket::Article, :count).by(2)

            expect(ticket1.reload.articles.last.body).to eq('bulk note body')
            expect(ticket1.articles.last.type.name).to eq('note')
            expect(ticket2.reload.articles.last.body).to eq('bulk note body')
            expect(ticket2.articles.last.type.name).to eq('note')
          end

          context 'when one ticket update fails' do
            before do
              allow_any_instance_of(Service::Ticket::Update).to receive(:execute).and_wrap_original do |m, *args, **kwargs|
                if kwargs[:ticket].title == 'Ticket 2'
                  raise ActiveRecord::RecordNotSaved.new('test failure during update of second ticket', ticket2)
                end

                m.call(*args, **kwargs)
              end
            end

            it 'processes successful tickets and isolates failures' do
              perform_enqueued_jobs do
                gql.execute(query, variables:)
                expect(gql.result.data).to include(async: true, total: 2)
              end

              # Ticket 1 should have the note added
              expect(ticket1.reload.articles.last.body).to eq('bulk note body')
              expect(ticket1.articles.last.type.name).to eq('note')

              # Ticket 2 should not have a new article (failure was isolated)
              ticket2.reload
              expect(ticket2.articles.where(body: 'bulk note body')).to be_empty
            end
          end

          context 'when permission is denied for one ticket' do
            before do
              allow_any_instance_of(TicketPolicy).to receive(:agent_update_access?).and_wrap_original do |m, *args|
                ticket = m.receiver.record
                if ticket.title == 'Ticket 2'
                  false
                else
                  m.call(*args)
                end
              end
            end

            it 'processes authorized tickets and isolates permission failures' do
              perform_enqueued_jobs do
                gql.execute(query, variables:)
                expect(gql.result.data).to include(async: true, total: 2)
              end

              # Ticket 1 should have the note added
              expect(ticket1.reload.articles.last.body).to eq('bulk note body')
              expect(ticket1.articles.last.type.name).to eq('note')

              # Ticket 2 should not have a new article (permission denied)
              ticket2.reload
              expect(ticket2.articles.where(body: 'bulk note body')).to be_empty
            end
          end
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  describe 'selector validation', authenticated_as: :agent do
    let(:ticket_ids)   { nil }
    let(:overview_id)  { nil }
    let(:search_query) { nil }
    let(:selector)     { { entityIds: ticket_ids, overviewId: overview_id, searchQuery: search_query } }

    before do
      allow_any_instance_of(described_class).to receive(:resolve)
    end

    context 'when no arguments provided' do
      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error)
          .to include(message: 'Exactly one of entity_ids, overview_id, or search_query must be provided.')
      end
    end

    context 'when multiple arguments provided' do
      let(:ticket_ids) { [1, 2] }
      let(:search_query) { 'query' }

      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error)
          .to include(message: 'Exactly one of entity_ids, overview_id, or search_query must be provided.')
      end
    end

    context 'when only entity_ids provided' do
      let(:ticket)     { create(:ticket) }
      let(:ticket_ids) { [gql.id(ticket)] }

      it 'passes ticket internal IDs to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(entity_ids: [ticket.id]), perform: anything)

        gql.execute(query, variables:)
      end
    end

    context 'when only overview_id provided' do
      let(:overview) { create(:overview) }
      let(:overview_id) { gql.id(overview) }

      it 'passes overview to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(overview:), perform: anything)

        gql.execute(query, variables:)
      end
    end

    context 'when only search_query provided' do
      let(:search_query) { 'query' }

      it 'passes search query to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: hash_including(search_query:), perform: anything)

        gql.execute(query, variables:)
      end
    end
  end

  describe 'perform validation', authenticated_as: :agent do
    let(:input)    { {} }
    let(:macro_id) { nil }
    let(:perform)  { { input:, macroId: macro_id } }

    before do
      allow_any_instance_of(described_class).to receive(:resolve)
    end

    context 'when no performs provided' do
      it 'raises an error' do
        gql.execute(query, variables:)

        expect(gql.result.error)
          .to include(message: 'At least one of input or macro_id must be provided.')
      end
    end

    context 'when only input provided' do
      let(:input) { { title: 'New Title' } }

      it 'passes input to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: anything, perform: hash_including(input:))

        gql.execute(query, variables:)
      end
    end

    context 'when only macro_id provided' do
      let(:macro)    { create(:macro) }
      let(:macro_id) { gql.id(macro) }

      it 'passes macro to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: anything, perform: hash_including(macro:))

        gql.execute(query, variables:)
      end
    end

    context 'when both input and macro_id provided' do
      let(:input) { { title: 'New Title' } }
      let(:macro)    { create(:macro) }
      let(:macro_id) { gql.id(macro) }

      it 'passes both input and macro to resolve' do
        expect_any_instance_of(described_class)
          .to receive(:resolve)
          .with(selector: anything, perform: hash_including(input:, macro:))

        gql.execute(query, variables:)
      end
    end
  end
end
