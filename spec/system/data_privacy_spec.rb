# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Data Privacy', authenticated_as: :authenticate, type: :system do
  let(:customer) { create(:customer, firstname: 'Frank1') }
  let(:ticket)   { create(:ticket, customer: customer, group: Group.find_by(name: 'Users')) }

  def authenticate
    customer
    ticket
    true
  end

  context 'when data privacy admin interface' do
    it 'deletes customer' do
      visit 'system/data_privacy'
      click '.js-new'

      find(:css, '.js-input').send_keys(customer.firstname)
      expect(page).to have_css('.searchableSelect-option-text')
      click '.searchableSelect-option-text'
      fill_in 'Are you sure?', with: 'DELETE'
      expect(page).to have_no_text('DELETE ORGANIZATION?')
      click '.js-submit'

      expect(page).to have_text('in process')
      DataPrivacyTaskJob.perform_now
      expect(page).to have_text('completed')
    end

    context 'when customer is the single user of the organization' do
      let(:organization) { create(:organization) }
      let(:customer) { create(:customer, firstname: 'Frank2', organization: organization) }

      def authenticate
        organization
        customer
        ticket
        true
      end

      it 'deletes customer' do
        visit 'system/data_privacy'
        click '.js-new'

        find(:css, '.js-input').send_keys(customer.firstname)
        expect(page).to have_css('.searchableSelect-option-text')
        click '.searchableSelect-option-text'
        fill_in 'Are you sure?', with: 'DELETE'
        expect(page).to have_text('DELETE ORGANIZATION?')
        click '.js-submit'

        expect(page).to have_text('in process')
        DataPrivacyTaskJob.perform_now
        expect(page).to have_text('completed')
      end

      it 'deletes customer by email' do
        visit 'system/data_privacy'
        click '.js-new'

        find(:css, '.js-input').send_keys(customer.email)
        expect(page).to have_css('.searchableSelect-option-text')
        click '.searchableSelect-option-text'
        fill_in 'Are you sure?', with: 'DELETE'
        expect(page).to have_text('DELETE ORGANIZATION?')
        click '.js-submit'

        expect(page).to have_text('in process')
        DataPrivacyTaskJob.perform_now
        expect(page).to have_text('completed')
      end
    end
  end

  context 'when user profile' do
    it 'deletes customer' do
      visit "user/profile/#{customer.id}"

      click '.dropdown--actions'
      click_on 'Delete'

      fill_in 'Are you sure?', with: 'DELETE'
      click '.js-submit'

      expect(page).to have_text('in process')
      DataPrivacyTaskJob.perform_now
      expect(page).to have_text('completed')
    end
  end

  context 'when ticket zoom' do
    it 'deletes customer' do
      visit "ticket/zoom/#{ticket.id}"

      click '.tabsSidebar-tab[data-tab=customer]'
      click 'h2.js-headline'
      click_on 'Delete Customer'

      fill_in 'Are you sure?', with: 'DELETE'
      click '.js-submit'

      expect(page).to have_text('in process')
      DataPrivacyTaskJob.perform_now
      expect(page).to have_text('completed')
    end
  end
end
