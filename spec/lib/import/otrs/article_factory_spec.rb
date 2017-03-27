require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::ArticleFactory do
  it_behaves_like 'Import::Factory'
end
