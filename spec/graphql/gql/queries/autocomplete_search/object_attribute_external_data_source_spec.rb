# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::ObjectAttributeExternalDataSource, :aggregate_failures, authenticated_as: :agent, db_adapter: :postgresql, type: :graphql do

  context 'when searching for values in external data source object attributes' do
    let(:attribute)   { create(:object_manager_attribute_autocompletion_ajax_external_data_source, object_name:) }
    let(:object_name) { 'Ticket' }
    let(:group)       { create(:group) }
    let(:agent)       { create(:agent, groups: [group]) }
    let(:query) do
      <<~QUERY
        query autocompleteSearchObjectAttributeExternalDataSource($input: AutocompleteSearchObjectAttributeExternalDataSourceInput!) {
          autocompleteSearchObjectAttributeExternalDataSource(input: $input) {
            value
            label
          }
        }
      QUERY
    end
    let(:ticket) { create(:ticket, group: group) }
    let(:variables)      { { input: { 'object' => attribute.object_lookup.name, attributeName: attribute.name, query: 'abc', templateRenderContext: { ticketId: gql.id(ticket) } } } }
    let(:mocked_payload) { [{ 'value' => 'abc', 'label' => 'abc' }] }

    before do
      allow(ExternalDataSource).to receive(:new).and_call_original
      allow_any_instance_of(ExternalDataSource).to receive(:process).and_return(mocked_payload)
    end

    context 'when called for a valid object attribute' do
      it 'returns correct data' do
        gql.execute(query, variables: variables)
        expect(gql.result.data).to eq(mocked_payload)
        expect(ExternalDataSource).to have_received(:new).with(include(render_context: { ticket: ticket, user: agent }))
      end
    end

    context 'when called for a nonexisting object attribute' do
      let(:variables) { { input: { 'object' => attribute.object_lookup.name, attributeName: 'nonexisting', query: 'abc', templateRenderContext: { ticketId: gql.id(ticket) } } } }

      it 'raises an error' do
        gql.execute(query, variables: variables)
        expect(gql.result.error_message).to include('Could not find object attribute')
        expect(gql.result.error_type).to eq(RuntimeError)
      end
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end

    context 'when insufficient permissions' do
      let(:object_name) { 'Group' }

      before do
        gql.execute(query, variables: variables)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
