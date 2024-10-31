# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::LinkUpdates, type: :graphql do
  let(:subscription) do
    <<~SUBSCRIPTION
      subscription linkUpdates($objectId: ID!, $targetType: String!) {
        linkUpdates(objectId: $objectId, targetType: $targetType) {
          links {
            item {
              ... on Ticket {
                id
              }
            }
            type
          }
        }
      }
    SUBSCRIPTION
  end

  let(:mock_channel)  { build_mock_channel }
  let(:from_group)    { create(:group) }
  let(:from)          { create(:ticket, group: from_group) }
  let(:to_group)      { create(:group) }
  let(:to)            { create(:ticket, group: to_group) }
  let(:type)          { ENV.fetch('LINK_TYPE') { %w[child parent normal].sample } }
  let(:link)          { create(:link, from:, to:) }
  let(:variables)     { { objectId: gql.id(from), targetType: 'Ticket' } }

  before do
    link
    gql.execute(subscription, variables: variables, context: { channel: mock_channel })

    next if RSpec.configuration.formatters.first
      .class.name.exclude?('DocumentationFormatter')

    puts "with link type: #{type}" # rubocop:disable Rails/Output
  end

  context 'with authenticated user', authenticated_as: :agent do

    context 'when object is not accessible' do
      let(:agent) { create(:agent) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when object is accessible' do
      let(:agent) { create(:agent, groups: [ from_group, to_group ]) }

      it 'subscribes to the channel' do
        expect(gql.result.data).to eq({ 'links' => nil })
      end

      context 'when link is updated' do
        it 'receives updates' do
          link.save!
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['linkUpdates']['links']).to be_present
        end
      end

      context 'when link is destroyed' do
        it 'receives updates' do
          link.destroy
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['linkUpdates']['links']).to be_empty
        end
      end

      context 'when link target is destroyed' do
        it 'receives updates' do
          to.destroy
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['linkUpdates']['links']).to be_empty
        end
      end

      context 'when link source is destroyed' do
        it 'receives no updates' do
          from.destroy
          expect(mock_channel.mock_broadcasted_messages).to be_empty
        end
      end

      context 'when link target is updated' do
        it 'receives updates' do
          to.update!(title: 'New title')
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['linkUpdates']['links']).to be_present
        end
      end

      context 'when reverse link is created' do
        it 'receives updates' do
          create(:link, from: to, to: from)
          expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['linkUpdates']['links']).to be_present
        end
      end
    end
  end
end
