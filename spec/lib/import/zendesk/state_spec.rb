require 'rails_helper'
require 'lib/import/zendesk/lookup_backend_examples'

RSpec.describe Import::Zendesk::State do
  it_behaves_like 'Lookup backend'

  it 'looks up ticket state' do

    ticket       = double(status: nil)
    dummy_result = 'dummy result'
    expect(::Ticket::State).to receive(:lookup).and_return(dummy_result)
    expect(described_class.lookup(ticket)).to eq(dummy_result)
  end
end
