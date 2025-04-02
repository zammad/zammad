# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::System::Setup::Lock, :aggregate_failures, type: :graphql do
  context 'when locking system setup' do
    let(:mutation) do
      <<~MUTATION
        mutation systemSetupLock($ttl: Int) {
          systemSetupLock(ttl: $ttl) {
            resource
            value
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
    let(:ttl)       { 1 }
    let(:lock_info) { { resource: resource, value: value } }
    let(:variables) { { ttl: ttl } }

    it 'returns lock info' do
      allow_any_instance_of(Redlock::Client).to receive(:lock).with(resource, ttl).and_return(lock_info)

      gql.execute(mutation, variables: variables)
      expect(gql.result.data).to include({ 'resource' => resource, 'value' => value })
    end

    context 'when system setup is already done' do
      before do
        Setting.set('system_init_done', true)
      end

      it 'raises error' do
        gql.execute(mutation, variables: variables)
        expect { gql.result.data }.to raise_error(RuntimeError)
      end
    end

    context 'when system setup is already locked' do
      it 'raises error' do
        allow_any_instance_of(Redlock::Client).to receive(:locked?).with(resource).and_return(true)

        gql.execute(mutation, variables: variables)
        expect { gql.result.data }.to raise_error(RuntimeError)
      end
    end
  end
end
