# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::PublicLinkUpdates, type: :graphql do
  let(:mock_channel) { build_mock_channel }

  let(:variables) { { screen: 'login' } }
  let(:subscription) do
    <<~QUERY
      subscription publicLinkUpdates($screen: EnumPublicLinksScreen!) {
        publicLinkUpdates(screen: $screen) {
          publicLinks {
            id
            link
            title
            description
            newTab
          }
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
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'publicLinks' => nil })
    end

    it 'receives public link updates' do
      link_list[:second].update!(title: 'dummy')

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'publicLinkUpdates', 'publicLinks')[1]['title']).to eq('dummy')
    end

    it 'receives updates whenever a public link was created' do
      create(:public_link, prio: 4)

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'publicLinkUpdates', 'publicLinks').size).to eq(4)
    end

    it 'receives updates whenever a public link was deleted' do
      link_list[:second].destroy!

      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'publicLinkUpdates', 'publicLinks').size).to eq(2)
    end
  end
end
