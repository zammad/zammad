# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Caller log', type: %i[system request], authenticated_as: true do # rubocop:disable RSpec/DescribeClass
  let(:admin) do
    create(:admin, groups: Group.all)
  end

  let!(:customer) { create(:customer, phone: '0190333') }

  let(:params) do
    {
      direction: 'in',
      from:      '0190333',
      to:        '0190111',
      callId:    '111',
      cause:     'busy'
    }
  end

  def prepare
    Setting.set('cti_integration', true)
    Setting.set('cti_token', 'token1234')
    current_user.update(phone: '0190111')
  end

  context 'without active tickets' do
    it 'checks opening of the ticket creation screen after phone call inbound' do
      prepare

      travel(-2.months)
      create(:ticket, customer: customer)
      travel_back

      visit 'cti'

      post "#{Capybara.app_host}/api/v1/cti/token1234", params: params.merge(event: 'newCall'), as: :json
      post "#{Capybara.app_host}/api/v1/cti/token1234", params: params.merge(event: 'answer', answeringNumber: '0190111' ), as: :json

      within(:active_content) do
        expect(page).to have_text('New Ticket', wait: 5)
      end
    end
  end

  context 'with active tickets' do
    it 'checks opening of the user profile screen after phone call inbound with tickets in the last month' do
      prepare

      create(:ticket, customer: customer)

      visit 'cti'

      post "#{Capybara.app_host}/api/v1/cti/token1234", params: params.merge(event: 'newCall'), as: :json
      post "#{Capybara.app_host}/api/v1/cti/token1234", params: params.merge(event: 'answer', answeringNumber: '0190111' ), as: :json

      within(:active_content) do
        expect(page).to have_text(customer.fullname, wait: 5)
      end
    end
  end
end
