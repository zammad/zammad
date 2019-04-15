require 'rails_helper'

RSpec.describe 'Unauthenticated redirect', type: :system, authenticated: false do

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
end
