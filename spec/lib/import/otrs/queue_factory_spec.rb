require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::QueueFactory do
  it_behaves_like 'Import::Factory'
end
