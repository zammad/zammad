# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Auto wizard', type: :system, set_up: false do

  it 'Automatic setup and login' do

    FileUtils.ln(
      Rails.root.join('contrib/auto_wizard_test.json'),
      Rails.root.join('auto_wizard.json'),
      force: true
    )

    visit 'getting_started/auto_wizard'

    expect(current_login).to eq('admin@example.com')
  end
end
