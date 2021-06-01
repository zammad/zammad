# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Tag, type: :request do

  describe 'request handling' do

    let(:agent) { create(:agent) }

    context 'tag search' do
      before do
        authenticated_as(agent)
      end

      let!(:tags) do
        [
          Tag::Item.lookup_by_name_and_create('foobar'),
          Tag::Item.lookup_by_name_and_create('xxxxxxxxx_DUMMY_VALUE1'),
          Tag::Item.lookup_by_name_and_create('121212121_DUMMY_VALUE2'),
          Tag::Item.lookup_by_name_and_create('oxoxoxoxo_DUMMY_VALUE3'),
        ]
      end

      let(:foobar_tag) { tags.first }

      shared_examples 'foobar tag found using' do |search_term:|
        it "found  1  tag  using search term '#{search_term}'" do
          get '/api/v1/tag_search', params: { term: search_term }
          expect(response).to have_http_status(:ok)
          expect(json_response).to contain_exactly( 'id' => foobar_tag.id, 'value' => foobar_tag.name )
        end
      end

      shared_examples 'no tag found using' do |search_term:|
        it "found  0  tags using search term '#{search_term}'" do
          get '/api/v1/tag_search', params: { term: search_term }
          expect(response).to have_http_status(:ok)
          expect(json_response).to contain_exactly()
        end
      end

      shared_examples 'all tags found using' do |search_term:|
        it "found all tags using search term '#{search_term}'" do
          get '/api/v1/tag_search', params: { term: search_term }
          expect(response).to have_http_status(:ok)
          expect(json_response.size).to eq(Tag::Item.count)
        end
      end

      describe 'using prefix search' do
        include_examples 'foobar tag found using', search_term: 'foobar'
        include_examples 'foobar tag found using', search_term: 'foo'
        include_examples 'foobar tag found using', search_term: 'f'
      end

      describe 'using substring search (added via Enhancement #2569 - Enhance tag search to use fulltext search)' do
        include_examples 'foobar tag found using', search_term: 'bar'
        include_examples 'foobar tag found using', search_term: 'ar'
        include_examples 'foobar tag found using', search_term: 'oo'
      end

      describe 'using wildcard search' do
        include_examples 'all tags found using', search_term: ' '
        include_examples 'all tags found using', search_term: '    '
      end

      describe 'using invalid search terms' do
        include_examples 'no tag found using', search_term: 'WRONG_VALUE'
        include_examples 'no tag found using', search_term: '-'
        include_examples 'no tag found using', search_term: 'fooar'
        include_examples 'no tag found using', search_term: '1foobar'
        include_examples 'no tag found using', search_term: 'foobar2'
      end
    end
  end
end
