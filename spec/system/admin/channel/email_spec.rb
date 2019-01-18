require 'rails_helper'

RSpec.describe 'Admin Panel > Channels > Email', type: :system, authenticated: true do
  # https://github.com/zammad/zammad/issues/224
  it 'hides "Edit" links when Channel#preferences[:editable] == false' do
    # ensure that the only existing email channel
    # has preferences == { editable: false }
    Channel.destroy_all
    create(:email_channel, preferences: { editable: false })

    visit '/#channels/email'
    expect(page).to have_css('#c-account h3', text: 'Inbound')  # Wait for frontend to load
    expect(page).to have_css('#c-account h3', text: 'Outbound') # Wait for frontend to load

    expect(page).not_to have_css('.js-editInbound, .js-editOutbound', text: 'Edit')
  end
end
