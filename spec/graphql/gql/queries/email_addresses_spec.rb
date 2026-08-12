# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::EmailAddresses, type: :graphql do

  context 'when fetching EmailAddresses' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query emailAddresses($onlyActive: Boolean = false) {
          emailAddresses(onlyActive: $onlyActive) {
            name
            email
            active
          }
        }
      QUERY
    end
    let(:variables) { { onlyActive: false } }
    let(:email_address) { create(:email_address) }

    before do
      email_address.update_columns(active: false)
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to eq([{ 'name' => email_address.name, 'email' => email_address.email, 'active' => false }])
      end

      context 'when fetching only active addresses' do
        let(:variables) do
          { onlyActive: true }
        end

        it 'does not include inactive addresses' do
          expect(gql.result.data).to eq([])
        end
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'when fetching the channel of an EmailAddress' do
    let(:admin)         { create(:admin) }
    let(:channel)       { create(:email_channel, options: { inbound: { options: { password: 'inbound-secret' } }, outbound: { options: { password: 'outbound-secret' } } }) }
    let(:email_address) { create(:email_address, channel: channel) }
    let(:query)         do
      <<~QUERY
        query emailAddresses {
          emailAddresses {
            email
            channel {
              options
            }
          }
        }
      QUERY
    end

    # the query returns every email address, so the created one must be picked explicitly
    let(:result_options) do
      gql.result.data
        .find { |elem| elem['email'] == email_address.email }
        &.dig('channel', 'options')
    end

    before do
      create(:email_address) # another address, so the lookup above cannot pass by accident
      email_address
      gql.execute(query)
    end

    context 'with an admin session', authenticated_as: :admin do
      it 'masks the sensitive channel options' do
        expect(result_options).to include(
          'inbound'  => { 'options' => { 'password' => SensitiveParamsHelper::SENSITIVE_MASK } },
          'outbound' => { 'options' => { 'password' => SensitiveParamsHelper::SENSITIVE_MASK } },
        )
      end

      it 'does not modify the channel options' do
        expect(channel.reload.options.dig('inbound', 'options', 'password')).to eq('inbound-secret')
      end
    end
  end
end
