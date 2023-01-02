# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'models/application_model/can_assets_examples'
require 'models/application_model/can_creates_and_updates_examples'
require 'models/application_model/checks_import_examples'

RSpec.shared_examples 'ApplicationModel' do |options = {}|
  include_examples 'ApplicationModel::CanAssets', options[:can_assets]
  include_examples 'ApplicationModel::CanCreatesAndUpdates'
  include_examples 'ApplicationModel::ChecksImport'
end
