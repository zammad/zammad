# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Caller log', authenticated_as: :authenticate, type: :system do
  let(:agent_phone)    { '0190111' }
  let(:customer_phone) { '0190333' }
  let(:agent)          { create(:agent, phone: agent_phone) }
  let(:customer)       { create(:customer, phone: customer_phone) }

  let(:params) do
    {
      direction: 'in',
      from:      customer.phone,
      to:        agent_phone,
      callId:    '111',
      cause:     'busy',
    }
  end

  let(:first_params) { params.merge(event: 'newCall') }
  let(:second_params) { params.merge(event: 'hangup') }

  let(:place_call) do
    token = Setting.get('sipgate_token')

    post "#{Capybara.app_host}/api/v1/sipgate/#{token}/in", params: first_params
    post "#{Capybara.app_host}/api/v1/sipgate/#{token}/in", params: second_params
  end

  def authenticate
    Setting.set('sipgate_integration', true)
    agent
  end

  # The caller log itself is covered by cti_spec.rb, this only checks the sipgate wiring.
  it 'shows incoming sipgate calls in the phone menu' do
    visit 'cti'
    ensure_websocket
    wait_for_authenticated_session(user: agent)

    place_call

    within '#navigation [href="#cti"].js-phoneMenuItem' do
      expect(page).to have_css('.counter', text: '1')
    end
  end
end
