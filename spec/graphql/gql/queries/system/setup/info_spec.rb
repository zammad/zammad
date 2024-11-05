# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::System::Setup::Info, :aggregate_failures, type: :graphql do
  context 'when quering system setup' do
    let(:query) do
      <<~QUERY
        query systemSetupInfo {
          systemSetupInfo {
            status
            type
          }
        }
      QUERY
    end

    context 'with a valid state' do
      it 'returns a string' do
        gql.execute(query)

        expect(gql.result.data[:status]).to be_a(String)
        expect(gql.result.data[:type]).to be_nil
      end
    end

    context 'with an invalid state' do
      before do
        allow(Service::System::CheckSetup).to receive(:new).and_return(
          instance_double(
            Service::System::CheckSetup,
            execute: nil,
            status:  'failed',
            type:    nil
          )
        )
      end

      it 'raises an error' do
        gql.execute(query)

        expect { gql.result.data }.to raise_error(RuntimeError)
      end
    end

  end
end
