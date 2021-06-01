# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Facebook', type: :system do
  context 'when configuring app' do
    before { visit '/#channels/facebook' }

    it 'works', :use_vcr do
      within :active_content do
        click '.btn--success'

        in_modal do
          fill_in 'application_id', with: ENV['FACEBOOK_APPLICATION_ID']
          fill_in 'application_secret', with: ENV['FACEBOOK_APPLICATION_SECRET']

          click '.btn--success'
        end

        expect(page).to have_text('Configure App')
      end
    end
  end
end
