# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::UserFactory do

  it 'skips root@localhost' do

    root_data = json_fixture('import/otrs/user/default')
    expect(Import::OTRS::User).not_to receive(:new)

    described_class.import([root_data])
  end
end
