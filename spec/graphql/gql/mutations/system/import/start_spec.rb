# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::System::Import::Start, type: :graphql do
  context 'when starting system import' do
    let(:mutation) do
      <<~MUTATION
        mutation systemImportStart {
          systemImportStart {
            success
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    context 'with missing configuration' do
      it 'raises an error' do
        gql.execute(mutation)
        expect { gql.result.data }.to raise_error(RuntimeError, %r{Please configure import source before running\.})
      end
    end

    context 'with valid configuration' do
      it 'succeeds' do
        allow_any_instance_of(Service::System::Import::Run).to receive(:execute).and_return(nil)
        Setting.set('import_backend', 'otrs')

        gql.execute(mutation)
        expect(gql.result.data).to include({ 'success' => true })
      end
    end
  end
end
