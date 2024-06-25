# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TemplateUpdates, :aggregate_failures, authenticated_as: :agent, type: :graphql do
  let(:mock_channel)             { build_mock_channel }
  let(:only_active_mock_channel) { build_mock_channel }
  let!(:template)                { create(:template) }
  let(:agent)                    { create(:agent) }
  let(:subscription) do
    <<~QUERY
      subscription templateUpdates($onlyActive: Boolean) {
        templateUpdates(onlyActive: $onlyActive) {
          templates {
            name
          }
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
    gql.execute(subscription, variables: { onlyActive: true }, context: { channel: only_active_mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'templates' => nil })
    end

    it 'receives template updates' do
      template.active = false
      template.save!
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates')).to eq(['name' => template.name])
      expect(only_active_mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates')).to eq([])
    end

    it 'receives updates whenever a template was created' do
      create(:template, active: false)
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates').size).to be(2)
      expect(only_active_mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates').size).to be(1)
    end

    it 'receives updates whenever a template was deleted' do
      template.destroy!
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates')).to eq([])
      expect(only_active_mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'templateUpdates', 'templates')).to eq([])
    end
  end
end
