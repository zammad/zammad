# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::System::Import::State, type: :graphql do
  context 'when checking system import state' do
    let(:query) do
      <<~QUERY
        query systemImportState {
          systemImportState {
            name
            result
            startedAt
            finishedAt
          }
        }
      QUERY
    end

    context 'with a running import job' do
      before do
        Setting.set('import_backend', 'freshdesk')
        Setting.set('import_mode', true)
        ImportJob.create!(name: 'Import::Freshdesk')
      end

      it 'returns the state' do
        gql.execute(query)
        expect(gql.result.data).to be_present.and(include('name' => 'Import::Freshdesk'))
      end

      context 'when the import source is OTRS' do
        let(:status) do
          {
            data:   {
              Base:   {
                done:  1,
                total: 100
              },
              User:   {
                done:  10,
                total: 10
              },
              Ticket: {
                done:  334,
                total: 11_472
              }
            },
            result: 'in_progress'
          }
        end

        before do
          Setting.set('import_backend', 'otrs')
          Setting.set('import_mode', true)

          allow_any_instance_of(Service::System::Import::CheckStatus).to receive(:execute).and_return(status)
        end

        context 'when the import is in progress' do
          it 'returns the state' do
            gql.execute(query)
            expect(gql.result.data).to be_present.and(include('name' => 'Import::Otrs'))
          end
        end

        context 'when error occurs during the import' do
          let(:status) do
            {
              message: 'Some error occurs during customer user creation.',
              result:  'error'
            }
          end

          it 'returns the error state' do
            gql.execute(query)
            expect(gql.result.data).to be_present.and(include('name' => 'Import::Otrs', 'result' => { error: 'Some error occurs during customer user creation.' }))
          end
        end
      end
    end

    context 'with finished import job' do
      before do
        Setting.set('import_backend', 'freshdesk')
        Setting.set('system_init_done', true)
        create(:admin)
        ImportJob.create!(name: 'Import::Freshdesk')
      end

      it 'returns the state' do
        gql.execute(query)
        expect(gql.result.data).to be_present.and(include('name' => 'Import::Freshdesk'))
      end
    end

    context 'with no running import job' do
      before do
        Setting.set('import_backend', 'freshdesk')
      end

      it 'returns the state' do
        gql.execute(query)
        expect(gql.result.data).to include({ 'result' => { error: 'No import in progress.' } })
      end
    end
  end
end
