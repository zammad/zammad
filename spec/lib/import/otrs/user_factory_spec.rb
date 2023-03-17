# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'lib/import/factory_examples'

RSpec.describe Import::OTRS::UserFactory do
  it_behaves_like 'Import::Factory'

  it 'skips root@localhost' do

    root_data = json_fixture('import/otrs/user/default')
    expect(Import::OTRS::User).not_to receive(:new)

    described_class.import([root_data])
  end
end
