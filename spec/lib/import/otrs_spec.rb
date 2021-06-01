# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/helper_examples'
require 'lib/import/importer_examples'
require 'lib/import/otrs/diff_examples'
require 'lib/import/async_examples'
require 'lib/import/import_stats_examples'

RSpec.describe Import::OTRS do
  it_behaves_like 'Import backend'
  it_behaves_like 'Import::Async'
  it_behaves_like 'Import::Helper'
  it_behaves_like 'Import::ImportStats'
  it_behaves_like 'Import::OTRS::Diff'
end
