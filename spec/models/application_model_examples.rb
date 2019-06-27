require 'models/application_model/can_assets_examples'
require 'models/application_model/can_associations_examples'
require 'models/application_model/can_latest_change_examples'
require 'models/application_model/checks_import_examples'

RSpec.shared_examples 'ApplicationModel' do |options = {}|
  include_examples 'ApplicationModel::CanAssets', options[:can_assets]
  include_examples 'ApplicationModel::CanAssociations'
  include_examples 'ApplicationModel::CanLatestChange'
  include_examples 'ApplicationModel::ChecksImport'
end
