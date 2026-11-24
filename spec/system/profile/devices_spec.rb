# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  context 'with the current device', authenticated_as: false, performs_jobs: true do
    before do
      login(username: 'admin@example.com', password: 'test')

      # The sign-in records the current device in a background job.
      perform_enqueued_jobs only: UserDeviceLogJob
    end

    it 'marks it and offers no delete control' do
      visit 'profile/devices'

      within(:active_content) do
        current_row = find('.badge', text: 'This device').ancestor('tr')
        expect(current_row).to have_no_css('.settings-list-control')

        expect(find('td', text: device.name).ancestor('tr')).to have_css('.settings-list-control')
      end
    end
  end
end
