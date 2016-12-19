require 'rails_helper'
require 'import/helper_examples'
require 'import/importer_examples'
require 'import/async_examples'
require 'import/import_stats_examples'

RSpec.describe Import::Zendesk do
  it_behaves_like 'Import backend'
  it_behaves_like 'Import::Helper'
  it_behaves_like 'Import::Async'
  it_behaves_like 'Import::ImportStats'
end
