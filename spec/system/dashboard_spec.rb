require 'rails_helper'

RSpec.describe 'Dashboard', type: :system, authenticated_as: true do

  it 'shows default widgets' do
    visit 'dashboard'

    expect(page).to have_css('.stat-widgets')
    expect(page).to have_css('.ticket_waiting_time > div > div.stat-title', text: /∅ Waiting time today/i)
    expect(page).to have_css('.ticket_escalation > div > div.stat-title', text: /Mood/i)
    expect(page).to have_css('.ticket_channel_distribution > div > div.stat-title', text: /Channel Distribution/i)
    expect(page).to have_css('.ticket_load_measure > div > div.stat-title', text: /Assigned/i)
    expect(page).to have_css('.ticket_in_process > div > div.stat-title', text: /Your tickets in process/i)
    expect(page).to have_css('.ticket_reopen > div > div.stat-title', text: /Reopening rate/i)
  end

  context 'when customer role is named different', authenticated_as: :authenticate do
    def authenticate
      Role.find_by(name: 'Customer').update(name: 'Public')
      true
    end

    it 'invites a customer user' do
      visit 'dashboard'
      find('div.tab[data-area=first-steps-widgets]').click
      find('.js-inviteCustomer').click
      fill_in 'Firstname', with: 'Nick'
      fill_in 'Lastname', with: 'Braun'
      fill_in 'Email', with: 'nick.braun@zammad.org'
      click_on 'Invite'
      await_empty_ajax_queue
      expect(User.find_by(firstname: 'Nick').roles).to eq([Role.find_by(name: 'Public')])
    end
  end
end
