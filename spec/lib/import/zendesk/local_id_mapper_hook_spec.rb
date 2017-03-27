require 'rails_helper'
require 'lib/import/zendesk/local_id_mapper_hook_examples'

RSpec.describe Import::Zendesk::LocalIDMapperHook do
  it_behaves_like 'Import::Zendesk::LocalIDMapperHook'
end
