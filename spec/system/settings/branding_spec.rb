# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > Branding', type: :system do
  context 'when branding product name is changed' do
    before { visit '/#settings/branding' }

    let(:new_name) { 'ABC App' }

    it 'shows the new name in the page title' do
      within :active_content do
        within '#product_name' do
          fill_in 'product_name', with: new_name
          click_on 'Submit'
        end
      end

      expect(page).to have_title("#{new_name} - Branding")
    end
  end
end
