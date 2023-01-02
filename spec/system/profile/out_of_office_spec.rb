# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Out of Office', type: :system do
  before do
    visit 'profile/out_of_office'
  end

  it 'does find agents' do
    find(:css, '.js-objectSelect').send_keys('Agent')
    expect(page).to have_text('Agent 1 Test')
  end

  it 'does not find customers' do
    find(:css, '.js-objectSelect').send_keys('Nicole')
    expect(page).to have_no_text('Nicole Braun')
  end
end
