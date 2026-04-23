# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Search do
  let(:query)        { 'test_phrase' }
  let(:current_user) { create(:agent, groups: [Ticket.first.group]) }
  let(:objects)      { [User, Organization, Ticket] }
  let(:options)      { {} }

  describe '#execute' do
    subject(:service_result) { described_class.with_current_user(current_user).execute(query:, objects:, options:) }

    let(:customer) { create(:customer, firstname: query) }
    let(:organization) { create(:organization, name: query) }

    before do
      customer
      organization
    end

    it 'returns combined result with found items' do
      expect(service_result.result).to include(
        User         => include(objects: [customer], total_count: 1),
        Organization => include(objects: [organization], total_count: 1),
        Ticket       => include(objects: be_blank, total_count: 0)
      )
    end

    it 'lists models in the result in a specific order' do
      expect(service_result.result.keys).to eq [Ticket, User, Organization]
    end

    it 'lists flattened results in correct order' do
      expect(service_result.flattened).to eq [customer, organization]
    end

    context 'when objects are restricted' do
      let(:objects) { [User] }

      it 'searches given model only' do
        expect(service_result.result.keys).to eq [User]
      end
    end

    context 'with :only_ids option' do
      let(:options) { { only_ids: true } }

      context 'with ElasticSearch', searchindex: true do
        before do
          customer
          organization

          searchindex_model_reload([Ticket, User, Organization])
        end

        it 'returns only object ids in the result' do
          expect(service_result.result).to include(
            User         => [customer.id.to_s],
            Organization => [organization.id.to_s],
            Ticket       => be_blank
          )
        end

        context 'when searching for a ticket' do
          let(:query)   { 'Help' }
          let(:objects) { [Ticket] }

          it 'returns ticket ID' do
            expect(service_result.result).to include(
              Ticket => [Ticket.first.id.to_s]
            )
          end
        end
      end

      context 'with SQL fallback' do
        it 'returns only object ids in the result' do
          expect(service_result.result).to include(
            User         => [customer.id],
            Organization => [organization.id],
            Ticket       => be_blank
          )
        end

        context 'when searching for a ticket' do
          let(:query)   { 'Help' }
          let(:objects) { [Ticket] }

          it 'returns ticket ID' do
            expect(service_result.result).to include(
              Ticket => [Ticket.first.id]
            )
          end
        end
      end
    end
  end

  describe '#search_single_model', current_user_id: -> { current_user.id } do
    let(:instance) { described_class.new(query:, objects:, options:) }

    before do
      allow(SearchIndexBackend).to receive(:search_by_index)
      allow(User).to receive(:search)
      allow(Ticket).to receive(:search)
    end

    context 'when ElasticSearch is available' do
      before { allow(SearchIndexBackend).to receive(:enabled?).and_return(true) }

      context 'when direct index query allowed' do
        it 'uses SearchIndexBackend' do
          instance.send(:search_single_model, User)

          expect(SearchIndexBackend).to have_received(:search_by_index)
        end
      end

      context 'when direct index query not allowed' do
        it 'uses model#search' do
          instance.send(:search_single_model, Ticket)

          expect(Ticket).to have_received(:search)
        end
      end
    end

    context 'when ElasticSearch not available' do
      before { allow(SearchIndexBackend).to receive(:enabled?).and_return(false) }

      context 'when direct index query allowed' do
        it 'uses model#search' do
          instance.send(:search_single_model, User)

          expect(User).to have_received(:search)
        end
      end

      context 'when direct index query not allowed' do
        it 'uses model#search' do
          instance.send(:search_single_model, Ticket)

          expect(Ticket).to have_received(:search)
        end
      end
    end

    context 'with given options' do
      let(:options) { { limit: 123, offset: 1024 } }

      before { allow(SearchIndexBackend).to receive(:enabled?).and_return(true) }

      it 'forwards limit and offset arguments to model#search' do
        instance.send(:search_single_model, User)

        expect(SearchIndexBackend)
          .to have_received(:search_by_index)
          .with(anything, anything, include(limit: 123, offset: 1024))
      end

      it 'forwards limit and offset arguments to SearchIndexBackend' do
        instance.send(:search_single_model, Ticket)

        expect(Ticket)
          .to have_received(:search)
          .with(include(limit: 123, offset: 1024))
      end
    end
  end

  describe '#models', current_user_id: -> { user.id } do
    let(:instance) { described_class.new(query: 'test', objects: Models.searchable) }
    let(:models)   { instance.send(:models) }

    before do
      Setting.set('chat', true)
      create(:knowledge_base)
    end

    context 'when user is admin only' do
      let(:user) { create(:admin_only) }

      it 'returns all globally searchable models' do
        expect(models).to match(
          Organization                       => include(direct_search_index: true),
          User                               => include(direct_search_index: true),
          KnowledgeBase::Answer::Translation => include(direct_search_index: false),
        )
      end
    end

    context 'when user is admin with agent permissions' do
      let(:user) { create(:admin) }

      it 'returns all globally searchable models' do
        expect(models).to match(
          Organization                       => include(direct_search_index: true),
          Ticket                             => include(direct_search_index: false),
          User                               => include(direct_search_index: true),
          KnowledgeBase::Answer::Translation => include(direct_search_index: false),
          Chat::Session                      => include(direct_search_index: true),
        )
      end
    end

    context 'when user is agent' do
      let(:user) { create(:agent) }

      it 'returns all globally searchable models' do
        expect(models).to match(
          Organization                       => include(direct_search_index: true),
          Ticket                             => include(direct_search_index: false),
          User                               => include(direct_search_index: true),
          KnowledgeBase::Answer::Translation => include(direct_search_index: false),
          Chat::Session                      => include(direct_search_index: true),
        )
      end
    end

    context 'when user is customer' do
      let(:user) { create(:customer) }

      it 'returns all globally searchable models' do
        expect(models).to match(
          Organization => include(direct_search_index: false),
          Ticket       => include(direct_search_index: false),
        )
      end
    end
  end

end
