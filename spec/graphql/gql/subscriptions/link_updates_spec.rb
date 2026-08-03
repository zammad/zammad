# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
              ... on KnowledgeBaseAnswerTranslation {
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

    puts "with link type: #{type}"
  end

  context 'with authenticated user', authenticated_as: :agent do

    context 'when object is not accessible' do
      let(:agent) { create(:agent) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
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

    # The subscribed target type is the class of the *other* side of the link,
    # so a ticket subscribing to its knowledge base answer links must be
    # notified with 'KnowledgeBase::Answer::Translation' as target type.
    context 'when subscribing to knowledge base answer links of a ticket' do
      let(:agent)              { create(:agent, groups: [ from_group ]) }
      let(:answer_translation) { create(:knowledge_base_answer, :published).translation }
      let(:link)               { nil }
      let(:variables)          { { objectId: gql.id(from), targetType: 'KnowledgeBase::Answer::Translation' } }

      let(:broadcasted_links) do
        mock_channel.mock_broadcasted_messages.first&.dig(:result, 'data', 'linkUpdates', 'links')
      end

      it 'receives updates when an answer is linked' do
        create(:link, from: answer_translation, to: from, link_type: 'normal')

        expect(broadcasted_links).to contain_exactly(
          include('item' => { 'id' => gql.id(answer_translation) })
        )
      end

      it 'receives updates when an answer is unlinked' do
        answer_link = create(:link, from: answer_translation, to: from, link_type: 'normal')
        mock_channel.mock_broadcasted_messages.clear

        answer_link.destroy

        expect(broadcasted_links).to be_empty
      end
    end
  end
end
