require 'rails_helper'
require 'lib/import/zendesk/object_field_examples'

RSpec.describe Import::Zendesk::ObjectField do
  it_behaves_like 'Import::Zendesk::ObjectField'
end
