RSpec.shared_examples 'Sequencer::Unit::Import::Zendesk::SubSequence::Base' do
  before do
    allow(params[:client]).to receive(collection_name).and_return(client_collection)
    allow(client_collection).to receive(:all!).and_raise(api_error)
  end

  let(:params) do
    {
      dry_run: false,
      import_job: instance_double(ImportJob),
      client: double('ZendeskAPI'),
      group_map: {},         # required by Tickets
      organization_map: {},  # required by Tickets
      ticket_field_map: {},  # required by Tickets
      user_map: {},          # required by Tickets
    }
  end

  let(:collection_name) { described_class.name.demodulize.snakecase.to_sym }
  let(:client_collection) { double('ZendeskAPI::Collection') }
  let(:api_error) { ZendeskAPI::Error::NetworkError.new('Mock err msg', response_obj) }
  let(:response_obj) { double('Faraday::Response') }

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
        before { allow(response_obj).to receive(:status).and_return(500) }

        # https://github.com/zammad/zammad/issues/2262
        it 'does not rescue the resulting exception' do
          expect { process(params) }.to raise_error(api_error)
        end
      end
    end

    shared_examples 'Zendesk import data (available on all tiers)' do
      context 'if API returns 403 forbidden during sync' do
        before { allow(response_obj).to receive(:status).and_return(403) }

        it 'does not rescue the resulting exception' do
          expect { process(params) }.to raise_error(api_error)
        end
      end
    end

    if described_class.name.demodulize.in?(%w[UserFields OrganizationFields])
      include_examples 'Zendesk import data (only available on Team tier and up)'
    else
      include_examples 'Zendesk import data (available on all tiers)'
    end
  end
end
