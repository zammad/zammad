require 'rails_helper'
require 'import/factory_examples'

RSpec.describe Import::OTRS::PriorityFactory do
  it_behaves_like 'Import::Factory'

  it 'imports records' do

    import_data = {
      name: 'test',
    }
    expect(::Import::OTRS::Priority).to receive(:new).with(import_data)
    described_class.import([import_data])
  end
end
