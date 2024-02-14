# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Unauthenticated redirect', authenticated_as: false, type: :system do

  it 'Sessions' do
    visit 'system/sessions'
    expect_current_route 'login'
  end

  it 'Profile' do
    visit 'profile/linked'
    expect_current_route 'login'
  end

  it 'Ticket' do
    visit 'ticket/zoom/1'
    expect_current_route 'login'
  end

  it 'Not existing route' do
    visit 'not_existing'
    expect_current_route 'not_existing'
  end

  context 'when public', authenticated_as: false do
    it 'does redirect to login if no access' do
      visit '#profile'
      expect_current_route 'login'
    end
  end

  context 'when customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'does redirect to ticket view if no access' do
      visit '#ticket/create'
      expect_current_route 'profile'
    end
  end

  context 'when agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'does redirect to ticket view if no access' do
      visit '#customer_ticket_new'
      expect_current_route 'profile'
    end
  end

  context 'when admin', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    it 'does redirect to ticket view if no access' do
      visit '#customer_ticket_new'
      expect_current_route 'profile'
    end
  end
end
