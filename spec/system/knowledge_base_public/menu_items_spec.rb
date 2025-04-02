# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base menu items', authenticated_as: false, type: :system do
  include_context 'basic Knowledge Base'
  include_context 'Knowledge Base menu items'

  context 'menu items visibility' do
    before do
      published_answer

      visit help_no_locale_path
    end

    it 'shows header public link' do
      expect(page).to have_css('header .menu-item', text: menu_item_1.title)
    end

    it 'shows another header public link' do
      expect(page).to have_css('header .menu-item', text: menu_item_2.title)
    end

    it "doesn't show footer link in header" do
      expect(page).to have_no_css('header .menu-item', text: menu_item_3.title)
    end

    it 'shows footer public link' do
      expect(page).to have_css('footer .menu-item', text: menu_item_3.title)
    end

    it "doesn't show footer link of another locale" do
      expect(page).to have_no_css('footer .menu-item', text: menu_item_4.title)
    end

    it 'shows public links in given order' do
      index_1 = page.body.index menu_item_1.title
      index_2 = page.body.index menu_item_2.title
      expect(index_1).to be < index_2
    end
  end

  context 'menu items color' do
    before do
      knowledge_base.update! color_header_link: color
      visit help_no_locale_path
    end

    let(:color) { 'rgb(255, 0, 255)' }

    it 'applies color for header preview' do
      elem = first('.menu-item')

      expect(elem).to have_computed_style :color, color
    end

    it 'does not apply color for footer preview' do
      elem = all('.menu-item')[2]

      expect(elem).not_to have_computed_style :color, color
    end
  end
end
