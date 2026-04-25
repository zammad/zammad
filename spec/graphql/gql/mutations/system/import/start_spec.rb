# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
      before do
        Setting.set('import_backend', 'otrs')
      end

      it 'succeeds' do
        gql.execute(mutation)
        expect(gql.result.data).to include({ 'success' => true })
      end

      context 'with an already set up system' do
        before do
          Setting.set('system_init_done', true)
        end

        it 'raises an error' do
          gql.execute(mutation)
          expect(gql.result.error_type).to eq(Service::System::CheckSetup::SystemSetupError)
        end
      end
    end
  end
end
