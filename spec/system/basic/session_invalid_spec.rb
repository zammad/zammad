# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Session invalid detection', authenticated_as: true, authentication_type: :form, type: :system do
  context 'when session will be deleted on the backend' do
    it 'will redirect to login page after next request' do
      # Delete the session on backend
      SessionHelper.destroy(SessionHelper.list.first.id)

      click('.menu-item[href="#ticket/view"]')

      expect(page).to have_text('The session is no longer valid. Please log in again.')
    end
  end
end
