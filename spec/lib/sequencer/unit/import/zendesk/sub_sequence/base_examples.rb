# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'Sequencer::Unit::Import::Zendesk::SubSequence::Base' do
  describe 'error handling' do
    before do
      allow(params[:client]).to receive(collection_name).and_return(client_collection)

      # if method 'incremental_export' is defined in class add additional receive via incremental_export
      # for Users, Tickets and Organizations we are using Mixin 'IncrementalExport' to get the correct resource_collection method
      if "ZendeskAPI/#{collection_name}".classify.safe_constantize.respond_to?(:incremental_export)
        allow("ZendeskAPI/#{collection_name}".classify.safe_constantize).to receive(:incremental_export).and_return(client_collection)
      end

      allow(client_collection).to receive(:all!).and_raise(api_error)
    end

    let(:params) do
      {
        dry_run:          false,
        import_job:       instance_double(ImportJob),
        client:           double('ZendeskAPI'),
        group_map:        {}, # required by Tickets
        organization_map: {}, # required by Tickets
        ticket_field_map: {}, # required by Tickets
        user_map:         {}, # required by Tickets
      }
    end

    let(:collection_name) { described_class.name.demodulize.snakecase.to_sym }
    let(:client_collection) { double('ZendeskAPI::Collection') }
    let(:api_error_message) { 'Mock err msg' }
    let(:api_error) { ZendeskAPI::Error::NetworkError.new(api_error_message, response_obj) }

    let(:response_obj) do
      # stubbed methods required for ZendeskAPI::Error::ClientError#to_s
      double('Faraday::Response', method: :get, url: 'https://example.com', status: 500)
    end

    # https://github.com/zammad/zammad/issues/2262
    context 'for lowest-tier Zendesk subscriptions ("Essential")' do
      shared_examples 'Zendesk import data (only available on Team tier and up)' do
        context 'when API returns 403 forbidden during sync' do
          before { allow(response_obj).to receive(:status).and_return(403) }

          it 'rescues the resulting exception' do
            expect { process(params) }.not_to raise_error
          end
        end

        context 'when API returns other errors' do
          # https://github.com/zammad/zammad/issues/2262
          it 'does not rescue the resulting exception' do
            expect do
              process(params) do |unit|
                allow(unit).to receive(:sleep) # stub out this method to speed up retry cycle
              end
            end
              .to raise_error(api_error)
          end
        end
      end

      shared_examples 'Zendesk import data (available on all tiers)' do
        context 'if API returns 403 forbidden during sync' do
          before { allow(response_obj).to receive(:status).and_return(403) }

          it 'does not rescue the resulting exception' do
            expect do
              process(params) do |unit|
                allow(unit).to receive(:sleep) # stub out this method to speed up retry cycle
              end
            end.to raise_error(api_error)
          end
        end
      end

      if described_class.name.demodulize.in?(%w[UserFields OrganizationFields])
        include_examples 'Zendesk import data (only available on Team tier and up)'
      else
        include_examples 'Zendesk import data (available on all tiers)'
      end
    end

    context 'when DNS resolution fails (getaddrinfo: nodename nor servname provided, or not known)' do
      it 'retries ten times, in 10s intervals' do
        expect(client_collection)
          .to receive(:all!).exactly(11).times

        expect do
          process(params) do |unit|
            expect(unit).to receive(:sleep).with(10).exactly(10).times
          end
        end.to raise_error(api_error)
      end
    end

    context 'when execution timeout occurs' do
      let(:api_error_message) { "execution expired -- get https://example.zendesk.com/api/v2/#{collection_name}" }

      it 'retries ten times, in 10s intervals' do
        expect do
          process(params) do |unit|
            expect(unit).to receive(:sleep).with(10).exactly(10).times
          end
        end.to raise_error(api_error)
      end
    end
  end
end
