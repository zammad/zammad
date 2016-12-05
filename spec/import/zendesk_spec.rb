require 'rails_helper'
require 'import/importer_examples'

RSpec.describe Import::Zendesk do
  it_behaves_like 'Import backend'
end
