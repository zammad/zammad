# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Monitoring', type: :system do

  context 'when showing the token' do
    it 'works correctly' do
      visit 'system/monitoring'

      within :active_content do
        token = find('.js-token').value
        url   = find('.js-url').value
        expect(url).to include(token)

        click '.js-resetToken'
        new_token = find('.js-token').value
        new_url   = find('.js-url').value
        expect(new_url).to include(new_token)
        expect(token).not_to eq(new_token)
      end
    end
  end
end
