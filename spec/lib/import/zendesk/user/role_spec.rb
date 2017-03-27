require 'rails_helper'
require 'lib/import/zendesk/user/lookup_backend_examples'

# required due to some of rails autoloading issues
require 'import/zendesk/user/role'

RSpec.describe Import::Zendesk::User::Role do
  it_behaves_like 'lookup backend'

  it 'responds to map' do
    expect(described_class).to respond_to(:map)
  end
end
