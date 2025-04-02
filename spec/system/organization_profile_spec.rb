# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Organization Profile', type: :system do
  let(:organization) { create(:organization) }

  it 'does show the edit link' do
    visit "#organization/profile/#{organization.id}"
    click '#userAction label'
    click_on 'Edit'
    modal_ready
  end

  context 'with active attribute' do
    it 'shows regular building icon if organization is active' do
      organization = create(:organization, active: true)

      visit "#organization/profile/#{organization.id}"

      within '.avatar--organization' do
        expect(page).to have_css('.icon-organization')
      end
    end

    it 'shows crossed out building icon if organization is inactive' do
      visit "#organization/profile/#{organization.id}"

      within '.avatar--organization' do
        expect(page).to have_no_css('.icon-inactive')
      end
    end
  end

  context 'with vip attribute' do
    it 'shows vip crown if organization is vip' do
      organization = create(:organization, vip: true)

      visit "#organization/profile/#{organization.id}"

      within '.avatar--organization' do
        expect(page).to have_css('.icon-crown-silver')
      end
    end

    it 'does not show vip crown if organization is not vip' do
      visit "#organization/profile/#{organization.id}"

      within '.avatar--organization' do
        expect(page).to have_no_css('.icon-crown-silver')
      end
    end
  end

  context 'with members section' do
    let(:members) { organization.members.reorder(id: :asc) }

    before do
      create_list(:customer, 50, organization: organization)
      visit "#organization/profile/#{organization.id}"
    end

    it 'shows first 10 members and loads more on demand' do
      expect(page).to have_text(members[9].fullname)
      expect(page).to have_no_text(members[10].fullname)

      click '.js-showMoreMembers'
      expect(page).to have_text(members[10].fullname)
    end
  end

  context 'when ticket changes in organization profile', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, title: SecureRandom.uuid, customer: create(:customer, :with_org), group: Group.first) }

    def authenticate
      ticket
      true
    end

    before do
      visit "#organization/profile/#{ticket.customer.organization.id}"
    end

    it 'does update when ticket changes' do
      expect(page).to have_text(ticket.title)
      ticket.update(title: SecureRandom.uuid)
      expect(page).to have_text(ticket.title)
    end
  end
end
