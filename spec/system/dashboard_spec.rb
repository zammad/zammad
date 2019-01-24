require 'rails_helper'

RSpec.describe 'Dashboard', type: :system, authenticated: true do

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
end
