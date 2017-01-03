require 'rails_helper'
require 'import/factory_examples'
require 'import/zendesk/local_id_mapper_hook_examples'

RSpec.describe Import::Zendesk::OrganizationFieldFactory do
  it_behaves_like 'Import::Factory'
  it_behaves_like 'Import::Zendesk::LocalIDMapperHook'
end
