# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::TemplateUpdates, :aggregate_failures, type: :graphql do
  let(:mock_channel)             { build_mock_channel }
  let(:only_active_mock_channel) { build_mock_channel }
  let!(:template)                { create(:template) }
  let(:admin)                    { create(:admin) }
  let(:agent)                    { create(:agent) }
  let(:customer)                 { create(:customer) }
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

  let(:delivered)             { mock_channel.mock_broadcasted_messages.first&.dig(:result, 'data', 'templateUpdates', 'templates') }
  let(:only_active_delivered) { only_active_mock_channel.mock_broadcasted_messages.first&.dig(:result, 'data', 'templateUpdates', 'templates') }

  before do
    gql.execute(subscription, context: { channel: mock_channel })
    gql.execute(subscription, variables: { onlyActive: true }, context: { channel: only_active_mock_channel })
  end

  context 'with ticket.agent permission only', authenticated_as: :agent do

    it 'subscribes' do
      expect(gql.result.data).to eq({ 'templates' => nil })
    end

    it 'does not deliver inactive templates when a template is deactivated' do
      template.active = false
      template.save!

      expect(delivered).to eq([])
      expect(only_active_delivered).to eq([])
    end

    it 'does not deliver inactive templates when a template was created' do
      create(:template, active: false)

      expect(delivered).to eq([{ 'name' => template.name }])
      expect(only_active_delivered).to eq([{ 'name' => template.name }])
    end

    it 'receives updates whenever a template was deleted' do
      template.destroy!

      expect(delivered).to eq([])
      expect(only_active_delivered).to eq([])
    end
  end

  context 'with admin.template permission', authenticated_as: :admin do

    it 'delivers inactive templates as well' do
      inactive_template = create(:template, active: false)

      expect(delivered).to contain_exactly({ 'name' => template.name }, { 'name' => inactive_template.name })
      expect(only_active_delivered).to eq([{ 'name' => template.name }])
    end
  end

  context 'with ticket.customer permission only', authenticated_as: :customer do

    it 'fails with an authorization error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end

    it 'does not deliver any templates' do
      create(:template, active: false)

      expect(delivered).to be_nil
      expect(only_active_delivered).to be_nil
    end
  end
end
