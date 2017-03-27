require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::Factory do
  it_behaves_like 'Import::Factory'
  it_behaves_like 'Import::BaseFactory extender'
end
