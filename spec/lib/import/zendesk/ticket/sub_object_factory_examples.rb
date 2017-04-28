require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.shared_examples 'Import::Zendesk::Ticket::SubObjectFactory' do
  it_behaves_like 'Import::Factory'

  it 'tunnels local and remote ticket object to backend' do

    expect(described_class).to receive(:backend_class).and_return(Class)
    expect(described_class).to receive('skip?')
    expect(described_class).to receive(:pre_import_hook)
    expect(described_class).to receive(:post_import_hook)
    record         = double()
    local_ticket   = double()
    zendesk_ticket = double()
    expect(Class).to receive(:new).with(record, local_ticket, zendesk_ticket)
    parameter = double()
    expect(parameter).to receive(:each).and_yield(record)
    described_class.import(parameter, local_ticket, zendesk_ticket)
  end
end
