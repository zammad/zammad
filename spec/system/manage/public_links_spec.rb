# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Public Links', type: :system do
  context 'when creating a new public link' do
    it 'successfully creates a new public link' do
      visit '/#manage/public_links'

      click_on 'New Public Link'

      in_modal do
        fill_in 'link', with: 'https://zammad.org'
        fill_in 'title', with: 'Zammad <3'

        click_on 'Submit'
      end

      expect(page).to have_text('Zammad <3')
    end
  end

  context 'when performing different actions on a public link' do
    let(:public_link) { create(:public_link) }

    before do
      public_link

      visit '/#manage/public_links'
    end

    context 'when updating an existing public link' do
      it 'successfully updates an existing public link' do
        expect(page).to have_text('Zammad Homepage')

        find('td', text: 'Zammad Homepage').click

        in_modal do
          fill_in 'title', with: 'Zammad <3'

          click_on 'Submit'
        end

        expect(page).to have_text('Zammad <3')
      end
    end

    context 'when cloning an existing public link' do
      it 'successfully clones an existing public link' do
        expect(page).to have_text('Zammad Homepage')

        row = find('tr', text: 'Zammad Homepage')
        row.find('.js-action').click
        row.find('.js-clone').click

        in_modal do
          fill_in 'title', with: 'Zammad <3'
          fill_in 'link', with: 'https://zammad.org'

          click_on 'Submit'
        end

        expect(page).to have_text('Zammad Homepage')
        expect(page).to have_text('Zammad <3')
      end
    end

    context 'when deleting an existing public link' do
      it 'successfully deletes an existing public link' do
        expect(page).to have_text('Zammad Homepage')

        row = find('tr', text: 'Zammad Homepage')
        row.find('.js-action').click
        row.find('.js-delete').click

        in_modal do
          click_on 'delete'
        end

        expect(page).to have_no_text('Zammad Homepage')
      end
    end
  end
end
