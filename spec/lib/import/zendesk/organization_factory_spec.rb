require 'rails_helper'
require 'lib/import/factory_examples'
require 'lib/import/zendesk/local_id_mapper_hook_examples'

RSpec.describe Import::Zendesk::OrganizationFieldFactory do
  it_behaves_like 'Import::Factory'
  it_behaves_like 'Import::Zendesk::LocalIDMapperHook'
end
