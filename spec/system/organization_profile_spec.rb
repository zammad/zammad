# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Organization Profile', type: :system do

  context 'members section' do
    let(:organization) { create(:organization) }
    let(:members)      { organization.members.order(id: :asc) }

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
end
