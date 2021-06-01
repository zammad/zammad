# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Devices', type: :system, authenticated_as: true do
  subject!(:device) { create(:user_device, user_id: User.find_by(login: 'master@example.com').id) }

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
