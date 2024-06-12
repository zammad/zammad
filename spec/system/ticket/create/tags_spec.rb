# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket create > Tags', authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  before do
    visit 'ticket/create'
  end

  describe 'tags field behavior' do
    context 'when some tags exist in the system' do
      let(:tags) do
        [
          Tag::Item.lookup_by_name_and_create('tag 1'),
          Tag::Item.lookup_by_name_and_create('tag 2'),
          Tag::Item.lookup_by_name_and_create('tag 3'),
        ]
      end

      let(:first_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:second_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

      before do
        create(:tag, o: first_ticket, tag_item: tags.first)
        create(:tag, o: first_ticket, tag_item: tags.second)
        create(:tag, o: first_ticket, tag_item: tags.third)
        create(:tag, o: second_ticket, tag_item: tags.third)
      end

      it 'shows recommended tags (#4869)' do
        find('input[name="tags"] ~ input.token-input').click

        expect(page).to have_css('ul.ui-autocomplete > li.ui-menu-item', minimum: 3, wait: 30)

        click '.ui-menu-item', text: 'tag 3'

        expect(page).to have_css('.token', text: 'tag 3')
      end
    end
  end
end
