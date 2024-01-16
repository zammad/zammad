# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::System::Setup::Unlock, :aggregate_failures, type: :graphql do
  context 'when unlocking system setup' do
    let(:mutation) do
      <<~MUTATION
        mutation systemSetupUnlock($value: String!) {
          systemSetupUnlock(value: $value) {
            success
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    let(:resource)  { 'Zammad::System::Setup' }
    let(:value)     { SecureRandom.uuid }
    let(:lock_info) { { resource: resource, value: value } }
    let(:variables) { { value: value } }

    it 'returns success true' do
      allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(true)
      allow_any_instance_of(Redlock::Client).to receive(:unlock).with(lock_info).and_return(1)

      gql.execute(mutation, variables: variables)

      expect(gql.result.data).to include({ 'success' => true })
    end

    context 'when system setup is not locked' do
      it 'returns success false' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(false)

        gql.execute(mutation, variables: variables)
        expect(gql.result.data).to include({ 'success' => false })
      end
    end

  end
end
