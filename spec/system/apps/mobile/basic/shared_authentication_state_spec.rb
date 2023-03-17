# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Basic > Share authentication state between browser tabs', app: :mobile, type: :system do
  context 'when use logout action' do
    let(:agent)    { create(:agent) }

    it 'check that all tabs have been logged out', authenticated_as: :agent do
      visit '/'

      # open new tab
      open_window_and_switch
      visit '/'

      logout

      expect_current_route 'login'

      # Check that cookies has no longer a expire date after logout.
      cookie = cookie('^_zammad.+?')
      expect(cookie[:expires]).to be_nil

      switch_to_window_index(1)

      expect_current_route 'login'
    end
  end

  context 'when use login action' do
    let(:agent)    { create(:agent) }

    it 'check that all tabs have been logged in', authenticated_as: false do
      visit '/'

      # open new tab
      open_window_and_switch
      visit '/'

      login(
        username: agent.login,
        password: 'test',
      )

      expect_current_route '/'

      switch_to_window_index(1)

      expect_current_route '/'
    end
  end
end
