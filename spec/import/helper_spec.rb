require 'rails_helper'
require 'import/helper_examples'

RSpec.describe Import::Helper do
  it_behaves_like 'Import::Helper'

  it 'checks if import_mode is active' do
    expect(Setting).to receive(:get).with('import_mode').and_return(true)
    expect( described_class.check_import_mode ).to be true
  end

  it 'throws an exception if import_mode is disabled' do
    expect(Setting).to receive(:get).with('import_mode').and_return(false)
    expect { described_class.check_import_mode }.to raise_error(RuntimeError)
  end
end
