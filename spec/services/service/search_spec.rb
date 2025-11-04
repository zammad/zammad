# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Search do
  let(:query)        { 'test_phrase' }
  let(:current_user) { create(:agent) }
  let(:objects)      { [User, Organization, Ticket] }
  let(:options)      { {} }
  let(:instance)     { described_class.new(current_user:, query:, objects:, options:) }

  describe '#execute' do
    let(:customer) { create(:customer, firstname: query) }
    let(:organization) { create(:organization, name: query) }

    before do
      customer
      organization
    end

    it 'returns combined result with found items' do
      expect(instance.execute.result).to include(
        User         => include(objects: [customer], total_count: 1),
        Organization => include(objects: [organization], total_count: 1),
        Ticket       => include(objects: be_blank, total_count: 0)
      )
    end

    it 'lists models in the result in a specific order' do
      expect(instance.execute.result.keys).to eq [Ticket, User, Organization]
    end

    it 'lists flattened results in correct order' do
      expect(instance.execute.flattened).to eq [customer, organization]
    end

    context 'when objects are restricted' do
      let(:objects) { [User] }

      it 'searches given model only' do
        expect(instance.execute.result.keys).to eq [User]
      end
    end
  end

  describe '#search_single_model' do
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

  describe '#models' do
    let(:instance) { described_class.new(current_user: user, query: 'test', objects: Models.searchable) }
    let(:models) { instance.send(:models) }

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
