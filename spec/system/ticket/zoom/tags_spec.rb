# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Tags', type: :system do
  let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

  before do
    visit "#ticket/zoom/#{ticket.id}"
  end

  describe 'ticket add tag action' do
    context 'when some tags exist in the system' do
      let(:tags) do
        [
          Tag::Item.lookup_by_name_and_create('tag 1'),
          Tag::Item.lookup_by_name_and_create('tag 2'),
          Tag::Item.lookup_by_name_and_create('tag 3'),
        ]
      end

      let(:second_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:third_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

      before do
        create(:tag, o: second_ticket, tag_item: tags.first)
        create(:tag, o: second_ticket, tag_item: tags.second)
        create(:tag, o: second_ticket, tag_item: tags.third)
        create(:tag, o: third_ticket, tag_item: tags.third)
      end

      it 'shows recommended tags (#4869)' do
        click '.js-newTagLabel', text: 'Add Tag'

        expect(page).to have_css('ul.ui-autocomplete > li.ui-menu-item', minimum: 3, wait: 30)

        click '.ui-menu-item', text: 'tag 3'
        send_keys :tab

        expect(ticket.reload.tag_list).to include('tag 3')
      end
    end
  end
end
