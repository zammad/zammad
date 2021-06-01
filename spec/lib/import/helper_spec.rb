# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/helper_examples'

RSpec.describe Import::Helper do
  it_behaves_like 'Import::Helper'

  context 'import mode' do

    it 'checks if import_mode is active' do
      allow(Setting).to receive(:get).with('import_mode').and_return(true)

      expect( described_class.check_import_mode ).to be true
    end

    it 'throws an exception if import_mode is disabled' do
      allow(Setting).to receive(:get).with('import_mode').and_return(false)

      expect { described_class.check_import_mode }.to raise_error(RuntimeError)
    end
  end

  context 'system init' do

    it 'checks if system_init_done is active' do
      allow(Setting).to receive(:get).with('system_init_done').and_return(false)

      expect( described_class.check_system_init_done ).to be true
    end

    it 'throws an exception if system_init_done is disabled' do
      allow(Setting).to receive(:get).with('system_init_done').and_return(true)

      expect { described_class.check_system_init_done }.to raise_error(RuntimeError)
    end
  end

end
