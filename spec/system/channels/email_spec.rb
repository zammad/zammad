# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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

      expect(page).to have_no_css('.js-editInbound, .js-editOutbound', text: 'Edit')
    end
  end

  context 'when adding an email' do
    before do
      visit '#channels/email'
    end

    it 'one can switch between default and expert forms' do
      click '.js-channelNew'
      in_modal do
        click '.js-expert'
        expect(page).to have_text 'ORGANIZATION & DEPARTMENT NAME'
        expect(page).to have_text 'SSL/STARTTLS'
        expect(page).to have_text 'PORT'
        click '.js-close'
      end
    end

    it 'in the expert form, the port for SSL/NoSSL is set automatically only when it is default' do
      click '.js-channelNew'
      in_modal do
        click '.js-expert'
        expect(find('input[name="options::port"]').value).to eq('993')
        field = find('select[name="options::ssl"]')
        option_yes = field.find(:option, 'yes')
        option_no = field.find(:option, 'no')
        option_no.select_option
        expect(find('input[name="options::port"]').value).to eq('143')
        option_yes.select_option
        expect(find('input[name="options::port"]').value).to eq('993')
        option_no.select_option
        expect(find('input[name="options::port"]').value).to eq('143')
        port = '4242'
        fill_in 'options::port', with: port
        expect(find('input[name="options::port"]').value).to eq(port)
        option_yes.select_option
        expect(find('input[name="options::port"]').value).to eq(port)
        click '.js-close'
      end
    end

    it 'entered values on the default form are copied to the expert form' do
      click '.js-channelNew'
      in_modal do
        name = 'Area53'
        email = 'dont@ask.com'
        password = 'f34therRa!nSplash'
        fill_in 'realname', with: name
        fill_in 'email', with: email
        fill_in 'password', with: password
        click '.js-expert'
        expect(find('input[name="options::realname"]').value).to eq(name)
        expect(find('input[name="options::email"]').value).to eq(email)
        expect(find('input[name="options::user"]').value).to eq(email)
        expect(find('input[name="options::password"]').value).to eq(password)
        click '.js-close'
      end
    end
  end

  context 'when editing inbound email settings' do
    it 'the expert form fields are not shown' do
      visit '#channels/email'
      click '.js-channelEnable'
      click '.js-editInbound'
      in_modal do
        expect(page).to have_no_text 'ORGANIZATION & DEPARTMENT NAME'
        expect(page).to have_no_text 'ORGANIZATION SUPPORT'
        expect(page).to have_no_text 'EMAIL'
        click '.js-close'
      end
    end
  end
end
