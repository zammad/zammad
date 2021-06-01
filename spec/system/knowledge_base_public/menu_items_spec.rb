# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base menu items', type: :system, authenticated_as: false do
  include_context 'basic Knowledge Base'
  include_context 'Knowledge Base menu items'

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
