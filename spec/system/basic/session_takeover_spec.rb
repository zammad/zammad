# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Session takeover check', type: :system do
  context 'when use logout action' do
    let(:agent)    { create(:agent) }

    it 'check that all tabs have been logged out', authenticated_as: :agent do
      visit '/'

      # open new tab
      open_window_and_switch

      visit '/'

      # Go back and check for session takeover message
      switch_to_window_index(1)

      expect(page).to have_text('A new session was created with your account. This session will be stopped to prevent a conflict.')
    end
  end
end
