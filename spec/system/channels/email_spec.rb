require 'rails_helper'

RSpec.describe 'Manage > Channels > Email', type: :system do

  context 'non editable' do

    it 'hides "Edit" links' do
      # ensure that the only existing email channel
      # has preferences == { editable: false }
      Channel.destroy_all
      create(:email_channel, preferences: { editable: false })

      visit '/#channels/email'

      # verify page has loaded
      expect(page).to have_css('#c-account h3', text: 'Inbound')
      expect(page).to have_css('#c-account h3', text: 'Outbound')

      expect(page).not_to have_css('.js-editInbound, .js-editOutbound', text: 'Edit')
    end
  end
end
