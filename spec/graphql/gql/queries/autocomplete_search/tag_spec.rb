# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
        query autocompleteSearchTag($input: AutocompleteSearchInput!)  {
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
      let(:first_tag_payload) do
        {
          'value' => gql.id(tags.first),
          'label' => tags.first.name,
        }
      end
      let(:query_string) { tags.first.name }

      it 'has data' do
        expect(gql.result.data).to eq([first_tag_payload])
      end
    end

    context 'when sending an empty search string' do
      let(:query_string) { '   ' }

      it 'still returns tags' do
        expect(gql.result.data.length).to eq(tags.length)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
