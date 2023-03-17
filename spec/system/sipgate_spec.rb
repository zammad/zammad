# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Caller log', authenticated_as: :authenticate, type: :system do
  let(:agent_phone)    { '0190111' }
  let(:customer_phone) { '0190333' }
  let(:agent)          { create(:agent, phone: agent_phone) }
  let(:customer)       { create(:customer, phone: customer_phone) }
  let(:sipgate_on)     { true }

  let(:params) do
    {
      direction: 'in',
      from:      customer.phone,
      to:        agent_phone,
      callId:    '111',
      cause:     'busy',
    }
  end

  let(:first_params) { params.merge(event: 'newCall')  }
  let(:second_params) { params.merge(event: 'hangup')  }

  let(:place_call) do
    token = Setting.get('sipgate_token')

    post "#{Capybara.app_host}/api/v1/sipgate/#{token}/in", params: first_params
    post "#{Capybara.app_host}/api/v1/sipgate/#{token}/in", params: second_params
  end

  def authenticate
    Setting.set('sipgate_integration', sipgate_on)
    agent
  end

  context 'when sipgate integration is on' do
    it 'shows the phone menu in nav bar' do
      visit '/'

      within '#navigation .menu' do
        expect(page).to have_link('Phone', href: '#cti')
      end
    end
  end

  context 'when sipgate integration is not on' do
    let(:sipgate_on) { false }

    it 'does not show the phone menu in nav bar' do
      visit '/'

      within '#navigation .menu' do
        expect(page).to have_no_link('Phone', href: '#cti')
      end
    end
  end

  context 'with incoming call' do
    before do
      visit 'cti'
      place_call
    end

    it 'increments the call counter notification badge' do
      within '[href="#cti"].js-phoneMenuItem' do
        counter = find('.counter')
        expect(counter).to have_content 1
      end
    end
  end

  context 'when incoming call is checked' do
    before do
      visit 'cti'
      place_call
    end

    it 'clears the call counter notification badge' do
      within :active_content do
        find('.table-checkbox input.js-check', visible: :all).check allow_label_click: true
      end

      within '[href="#cti"].js-phoneMenuItem' do
        expect(page).to have_no_selector('.counter')
      end
    end
  end
end
