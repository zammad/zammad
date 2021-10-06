# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login', type: :system, authenticated_as: false do
  before do
    visit '/'
  end

  it 'fqdn is visible on login page' do
    expect(page).to have_css('.login p', text: Setting.get('fqdn'))
  end
end
