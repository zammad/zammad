# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::Tag, authenticated_as: :agent, type: :graphql do

  context 'when searching for tags' do
    let(:agent)        { create(:agent) }
    let!(:tags)        do
      create_list(:tag_item, 3).each_with_index do |tag, i|
        tag.name = "TagAutoComplete#{i}"
        tag.name_downcase = tag.name.downcase
        tag.save!
      end
    end
    let(:query) do
      <<~QUERY
        query autocompleteSearchTag($input: AutocompleteSearchTagInput!)  {
          autocompleteSearchTag(input: $input) {
            value
            label
          }
        }
      QUERY
    end
    let(:variables)    { { input: { query: query_string, limit: limit } } }
    let(:query_string) { 'TagAutoComplete' }
    let(:limit)        { nil }

    before do
      allow(Tag::Item).to receive(:recommended).and_call_original
      allow(Tag::Item).to receive(:filter_by_name).and_call_original
      gql.execute(query, variables: variables)
    end

    context 'without limit' do
      it 'finds all tags' do
        expect(gql.result.data.length).to eq(tags.length)
      end
    end

    context 'with limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data.length).to eq(limit)
      end
    end

    context 'with exact search' do
      let(:tag)          { tags.first }
      let(:query_string) { tag.name }

      let(:first_tag_payload) do
        {
          'value' => tag.name,
          'label' => tag.name,
        }
      end

      it 'has data' do
        expect(gql.result.data).to include(first_tag_payload)
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'returns recommended tags' do
        expect(Tag::Item).to have_received(:recommended)
      end
    end

    context 'when sending an asterisk' do
      let(:query_string) { '*' }

      it 'returns recommended tags' do
        expect(Tag::Item).to have_received(:recommended)
      end
    end

    context 'when asterisk is added to the query' do
      let(:query_string) { 'Tag*' }

      it 'returns filtered tags' do
        expect(Tag::Item).to have_received(:filter_by_name).with('Tag')
      end
    end

    context 'when tags are being excluded from the results' do
      let(:except_tags)  { %w[TagAutoComplete1 TagAutoComplete2] }
      let(:query_string) { 'Tag*' }
      let(:variables)    { { input: { query: query_string, limit: limit, exceptTags: except_tags } } }

      it 'returns filtered tags without excluded entries' do
        expect(gql.result.data).to include(
          include(
            'value' => not_include('TagAutoComplete1', 'TagAutoComplete2'),
            'label' => not_include('TagAutoComplete1', 'TagAutoComplete2'),
          )
        )
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'raises authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with a knowledge base editor without agent permission', authenticated_as: :kb_editor do
      let(:role)      { create(:role, permission_names: %w[knowledge_base.editor]) }
      let(:kb_editor) { create(:customer, roles: [role]) }

      it 'finds all tags' do
        expect(gql.result.data.length).to eq(tags.length)
      end
    end

    context 'with an admin with tag administration permission', authenticated_as: :admin do
      let(:role)  { create(:role, permission_names: %w[admin.tag]) }
      let(:admin) { create(:user, roles: [role]) }

      it 'finds all tags' do
        expect(gql.result.data.length).to eq(tags.length)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
