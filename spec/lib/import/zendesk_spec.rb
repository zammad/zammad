require 'rails_helper'
require 'lib/import/helper_examples'
require 'lib/import/importer_examples'
require 'lib/import/async_examples'
require 'lib/import/import_stats_examples'

RSpec.describe Import::Zendesk do
  it_behaves_like 'Import backend'
  it_behaves_like 'Import::Helper'
  it_behaves_like 'Import::Async'
  it_behaves_like 'Import::ImportStats'
end
