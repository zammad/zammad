require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::Zendesk::Ticket::Comment::AttachmentFactory do
  it_behaves_like 'Import::Factory'

  it 'tunnels attachment and local article to backend' do
    expect(described_class).to receive(:backend_class).and_return(Class)
    expect(described_class).to receive('skip?')
    expect(described_class).to receive(:pre_import_hook)
    expect(described_class).to receive(:post_import_hook)
    record         = double()
    local_article  = double(attachments: [])
    expect(Class).to receive(:new).with(record, local_article)
    parameter = [record]
    described_class.import(parameter, local_article)
  end
end
