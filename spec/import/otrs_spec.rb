require 'rails_helper'
require 'import/helper_examples'
require 'import/importer_examples'
require 'import/otrs/async_examples'
require 'import/otrs/diff_examples'
require 'import/otrs/import_stats_examples'

RSpec.describe Import::OTRS do
  it_behaves_like 'Import backend'
  it_behaves_like 'Import::Helper'
  it_behaves_like 'Import::OTRS::Async'
  it_behaves_like 'Import::OTRS::Diff'
  it_behaves_like 'Import::OTRS::ImportStats'
end
