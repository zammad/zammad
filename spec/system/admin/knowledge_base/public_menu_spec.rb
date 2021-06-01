# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/266
RSpec.describe 'Admin Panel > Knowledge Base > Public Menu', type: :system, authenticated_as: true do
  include_context 'basic Knowledge Base'
  include_context 'Knowledge Base menu items'

  before do
    visit '/#manage/knowledge_base'
    find('a', text: 'Public Menu').click
  end

  context 'lists menu items' do
    it { expect(find_locale('Footer menu', alternative_locale).text).to include menu_item_4.title }
    it { expect(find_locale('Header menu', primary_locale).text).to include menu_item_1.title }
    it { expect(find_locale('Header menu', alternative_locale).text).not_to include menu_item_2.title }
    it { expect(find_locale('Header menu', primary_locale).text).to include menu_item_2.title }
  end

  context 'edit menu items' do
    before do
      find_location('Header menu').find('a', text: 'Edit').click

      modal_ready
    end

    it 'edit menu item' do
      find('input') { |elem| elem.value == menu_item_1.title }.fill_in with: 'test menu'
      find('button', text: 'Submit').click

      modal_disappear

      expect(find_locale('Header menu', primary_locale).text).to include 'test menu'
    end

    it 'adds menu item' do
      container = find(:css, '.modal-body h2', text: alternative_locale.system_locale.name).find(:xpath, '..')
      container.find('a', text: 'Add').click

      container.find('input') { |elem| elem['data-name'] == 'title' }.fill_in with: 'new item'
      container.find('input') { |elem| elem['data-name'] == 'url' }.fill_in with: '/new_item'

      find('button', text: 'Submit').click

      modal_disappear

      expect(find_locale('Header menu', alternative_locale).text).to include 'new item'
    end

    it 'deletes menu item' do
      find(:css, '.modal-body')
        .find('input') { |elem| elem.value == menu_item_1.title }
        .ancestor('tr')
        .find('.js-remove')
        .click

      find('button', text: 'Submit').click

      modal_disappear

      expect(find_locale('Header menu', alternative_locale).text).not_to include menu_item_1.title
    end
  end

  def find_locale(location, locale)
    find_location(location)
      .find('.label', text: %r{#{Regexp.escape locale.system_locale.name}}i)
      .ancestor('.kb-menu-preview')
  end

  def find_location(location)
    find('h3', text: location).ancestor('.settings-entry')
  end
end
