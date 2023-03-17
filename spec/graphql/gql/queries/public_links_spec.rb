# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::PublicLinks, type: :graphql do
  context 'when fetching public links' do
    let(:query) do
      <<~QUERY
        query publicLinks($screen: EnumPublicLinksScreen!) {
          publicLinks(screen: $screen) {
            id
            link
            title
            description
            newTab
          }
        }
      QUERY
    end

    let!(:link_list) do
      first_link  = create(:public_link, prio: 1)
      second_link = create(:public_link, prio: 2)
      third_link  = create(:public_link, prio: 3)

      {
        first:  first_link,
        second: second_link,
        third:  third_link,
      }
    end

    let(:expected_result) do
      [
        {
          'id'          => gql.id(link_list[:first]),
          'link'        => link_list[:first]['link'],
          'title'       => link_list[:first]['title'],
          'description' => link_list[:first]['description'],
          'newTab'      => link_list[:first]['new_tab'],
        },
        {
          'id'          => gql.id(link_list[:second]),
          'link'        => link_list[:second]['link'],
          'title'       => link_list[:second]['title'],
          'description' => link_list[:second]['description'],
          'newTab'      => link_list[:second]['new_tab'],
        },
        {
          'id'          => gql.id(link_list[:third]),
          'link'        => link_list[:third]['link'],
          'title'       => link_list[:third]['title'],
          'description' => link_list[:third]['description'],
          'newTab'      => link_list[:third]['new_tab'],
        },
      ]
    end

    before do
      gql.execute(query, variables: { screen: 'login' })
    end

    shared_examples 'returns public links' do
      it 'returns data' do
        expect(gql.result.data).to eq(expected_result)
      end
    end

    context 'when authorized', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      include_examples 'returns public links'
    end

    context 'when unauthorized' do
      include_examples 'returns public links'
    end
  end
end
