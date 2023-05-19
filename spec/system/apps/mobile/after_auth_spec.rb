# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > After Auth', app: :mobile, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  context 'when user is logged in, but after auth is required' do
    it 'requires setting up two factor auth' do
      allow_any_instance_of(Auth::AfterAuth::TwoFactorConfiguration).to receive(:check).and_return(true)

      visit '/', skip_waiting: true

      expect(page).to have_content('The two-factor authentication is not configured yet')
      expect_current_route '/login/after-auth'
    end
  end
end
