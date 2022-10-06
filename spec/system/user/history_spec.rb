# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket history', type: :system, time_zone: 'Europe/London' do
  let(:group)         { Group.find_by(name: 'Users') }
  let(:customer)      { create(:customer, organization: organization) }
  let!(:session_user) { User.find_by(login: 'admin@example.com') }
  let(:organization)  { create(:organization) }
  let(:org_name_1)    { 'organization test 1' }
  let(:org_name_2)    { 'organization test 2' }
  let(:org_1)         { create(:organization, name: org_name_1) }
  let(:org_2)         { create(:organization, name: org_name_2) }
  let(:locale)        { 'de-de' }

  before do
    freeze_time

    travel_to DateTime.parse('2021-01-22 13:40:00 UTC')
    current_time = Time.current
    customer.update! firstname: 'Customer'
    customer.update! email: 'test@example.com'
    customer.update! country: 'Germany'
    customer.update! out_of_office_start_at: current_time
    customer.update! last_login: current_time
    customer.organizations << [org_1, org_2]

    travel_to DateTime.parse('2021-04-06 23:30:00 UTC')
    current_time = Time.current
    customer.update! lastname: 'Example'
    customer.update! mobile: '5757473827'
    customer.update! out_of_office_end_at: current_time
    customer.update! last_login: current_time
    customer.organizations.delete(org_2)

    travel_back

    session_user.preferences[:locale] = locale
    session_user.save!

    # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
    page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"

    refresh

    visit "#user/profile/#{customer.id}"

    find_by_id('userAction').click
    click('[data-type="history"]')
  end

  it "translates timestamp when attribute's tag is datetime" do
    expect(page).to have_css('li', text: %r{'22.01.2021 00:00'})
  end

  it 'does not include time with UTC format' do
    expect(page).to have_no_text(%r{ UTC})
  end

  it 'translates out_of_office_start_at value to time stamp' do
    expect(page).to have_css('li', text: %r{Benutzer out_of_office_start_at '22.01.2021 00:00'})
  end

  it 'translates out_of_office_end_at value to time stamp' do
    expect(page).to have_css('li', text: %r{Benutzer out_of_office_end_at '06.04.2021 01:00'})
  end

  context 'when language is in english' do
    let(:locale) { 'en' }

    it 'shows added and removed secondary organizations' do
      in_modal do
        expect(page).to have_css('li', text: %r{added User Secondary organizations 'organization test 1'})
        expect(page).to have_css('li', text: %r{removed User Secondary organizations 'organization test 2'})
      end
    end
  end
end
