require 'rails_helper'
require 'lib/import/zendesk/user/lookup_backend_examples'

# required due to some of rails autoloading issues
require 'import/zendesk/user/group'

RSpec.describe Import::Zendesk::User::Group do
  it_behaves_like 'lookup backend'
end
