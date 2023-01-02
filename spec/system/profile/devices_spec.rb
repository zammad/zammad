# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Devices', type: :system do
  subject!(:device) { create(:user_device, user_id: User.find_by(login: 'admin@example.com').id) }

  it 'allows to remove device' do
    visit 'profile/devices'

    within(:active_content) do
      find('td', text: device.name)
        .ancestor('tr')
        .find('.settings-list-control')
        .click
    end

    expect(page).to have_no_css('td', text: device.name)
  end
end
