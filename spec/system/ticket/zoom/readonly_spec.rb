# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Access Zoom', type: :system, authenticated_as: :user do
  let(:group) { create(:group) }

  let!(:ticket) do
    create(:ticket, group: group).tap do |ticket|
      ticket.tag_add('Tag', 1)
      create(:link, from: create(:ticket, group: group), to: ticket)
    end
  end

  let(:user) do
    create(:agent).tap do |agent|
      agent.user_groups.create! group: group, access: group_access
    end
  end

  before do
    visit "ticket/zoom/#{ticket.id}"
  end

  shared_examples 'elements' do
    it 'verify all elements available' do
      %w[TAGS LINKS].each do |element|
        expect(page).to have_content(element)
      end
    end
  end

  context 'with full access' do
    let(:group_access) { :full }

    include_examples 'elements'

    it 'shows tag, and link modification buttons' do
      expect(page).to have_selector('.tags .icon-diagonal-cross')
      expect(page).to have_content('+ Add Tag')
      expect(page).to have_selector('.links .icon-diagonal-cross')
      expect(page).to have_content('+ Add Link')
    end
  end

  context 'with read access' do
    let(:group_access) { :read }

    include_examples 'elements'

    it 'shows no tag and link modification buttons' do
      expect(page).to have_no_selector('.tags .icon-diagonal-cross')
      expect(page).to have_no_content('+ Add Tag')
      expect(page).to have_no_selector('.links .icon-diagonal-cross')
      expect(page).to have_no_content('+ Add Link')
    end
  end
end
