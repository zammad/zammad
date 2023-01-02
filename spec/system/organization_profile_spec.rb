# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Organization Profile', type: :system do
  let(:organization) { create(:organization) }

  it 'does show the edit link' do
    visit "#organization/profile/#{organization.id}"
    click '#userAction label'
    click_link 'Edit'
    modal_ready
  end

  context 'members section' do
    let(:members) { organization.members.order(id: :asc) }

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
