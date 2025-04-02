# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'models/application_model/can_assets_examples'
require 'models/application_model/can_creates_and_updates_examples'
require 'models/application_model/can_param_examples'
require 'models/application_model/has_cache_examples'
require 'models/application_model/checks_import_examples'

RSpec.shared_examples 'ApplicationModel' do |options = {}|
  include_examples 'ApplicationModel::CanAssets', options[:can_assets]
  include_examples 'ApplicationModel::CanCreatesAndUpdates', options[:can_create_update]
  include_examples 'ApplicationModel::CanParam', options[:can_param]
  include_examples 'ApplicationModel::ChecksImport'
  include_examples 'ApplicationModel::HasCache'
end
