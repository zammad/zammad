# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Profile > Token Access', type: :system do
  let(:name)           { 'Some App Token' }
  let(:checkbox_input) { 'input[value="ticket.agent"]' }
  let(:expiry_date)    { '05/15/2024' }
  let(:token_list)     { find('.js-tokenList') }

  shared_examples 'having an error notification message' do
    it 'has error notification message' do
      within '#notify' do
        noty_message = find('.noty_message', visible: :all)
        expect(noty_message).to have_text(error_message)
      end
    end
  end

  context 'with valid fields' do
    before do
      visit 'profile/token_access'

      within :active_content do
        find('.js-create').click
      end

      # modal closes but it is swiftly replaced by another modal
      in_modal disappears: false do
        fill_in 'Name', with: name
        checkbox = find(checkbox_input, visible: :all)
        checkbox.check allow_label_click: true
        find('.js-datepicker').fill_in with: expiry_date
        send_keys(:tab)
        click_on 'Create'
      end
    end

    context 'with expire date' do
      it 'generates a new personal token' do
        in_modal do
          expect(page).to have_css('.form-control.input.js-select')
            .and have_text('Your New Personal Access Token')
        end
      end

      it 'shows active report profile' do
        in_modal do
          click_on "OK, I've copied my token"
        end

        within :active_content do
          expect(token_list).to have_text(name)
            .and have_text(expiry_date)
        end
      end
    end

    context 'without expire date' do
      let(:expiry_date) { nil }

      it 'generates a new personal token' do
        in_modal do
          expect(page).to have_css('.form-control.input.js-select')
            .and have_text('Your New Personal Access Token')
        end
      end

      it 'shows active report profile' do
        in_modal do
          click_on "OK, I've copied my token"
        end

        within :active_content do
          expect(token_list).to have_text(name)
        end
      end
    end
  end

  context 'with invalid fields' do
    before do
      visit 'profile/token_access'

      within :active_content do
        find('.content.active .js-create').click
      end

      in_modal disappears: false do
        fill_in 'name', with: name
        send_keys(:tab)
      end
    end

    context 'without name' do
      let(:name)          { nil }
      let(:error_message) { "The required parameter 'name' is missing." }

      before do
        in_modal disappears: false do
          checkbox = find(checkbox_input, visible: :all)
          checkbox.check allow_label_click: true
          click_on 'Create'
        end
      end

      it_behaves_like 'having an error notification message'
    end

    context 'without permission' do
      let(:name) { nil }
      let(:error_message) { "The required parameter 'permission' is missing." }

      before { click_on 'Create' }

      it_behaves_like 'having an error notification message'
    end
  end

  context 'with already created token', authenticated_as: :admin_user do
    let(:admin_user) { create(:admin) }
    let(:create_token) do
      create(:api_token,
             user:        admin_user,
             name:        name,
             preferences: { permission: %w[admin ticket.agent] })
    end

    before do
      create_token
      visit 'profile/token_access'
    end

    it 'shows the created token' do
      expect(token_list).to have_text(name)
    end

    it 'deletes created token' do
      token_delete_button = find('.js-tokenList tr .js-delete')
      token_delete_button.click

      in_modal do
        click_on 'Yes'
      end

      expect(token_list).to have_no_text(name)
    end
  end
end
