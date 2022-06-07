# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Home Page', type: :system, app: :mobile do
  context 'when on the home page', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before do
      visit '/mobile/'
    end

    it 'clicking on plus icon opens creating ticket' do
      icon = find_icon 'plus'
      icon.click
      expect_current_route 'ticket/create'
    end

    it '"all tickets" leads to tickets list' do
      tickets_link = find('a', text: 'All Tickets')
      expect(tickets_link[:href]).to match(%r{/mobile/tickets})
    end

    it 'home icon is highlighted on home page' do
      expect(page).to have_css('a[href="/mobile/"].text-blue')
    end

    it 'footer has my avatar' do
      me = find('a[href="/user"]')
      firstname = admin.firstname.first
      lastname = admin.lastname.first
      expect(me.text).to match("#{firstname}#{lastname}")
    end

  end
end
