# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'models/application_model/can_assets_examples'
require 'models/application_model/can_associations_examples'
require 'models/application_model/can_creates_and_updates_examples'
require 'models/application_model/can_latest_change_examples'
require 'models/application_model/can_lookup_examples'
require 'models/application_model/checks_import_examples'

RSpec.shared_examples 'ApplicationModel' do |options = {}|
  include_examples 'ApplicationModel::CanAssets', options[:can_assets]
  include_examples 'ApplicationModel::CanAssociations'
  include_examples 'ApplicationModel::CanCreatesAndUpdates'
  include_examples 'ApplicationModel::CanLatestChange'
  include_examples 'ApplicationModel::CanLookup'
  include_examples 'ApplicationModel::ChecksImport'
end
