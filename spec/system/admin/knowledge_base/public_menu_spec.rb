# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/266
RSpec.describe 'Admin Panel > Knowledge Base > Public Menu', type: :system do
  include_context 'basic Knowledge Base'
  include_context 'Knowledge Base menu items'

  context 'lists menu items' do
    before do
      visit '/#manage/knowledge_base'
      find('a', text: 'Public Menu').click
    end

    it { expect(find_locale('Footer Menu', alternative_locale).text).to include menu_item_4.title }
    it { expect(find_locale('Header Menu', primary_locale).text).to include menu_item_1.title }
    it { expect(find_locale('Header Menu', alternative_locale).text).not_to include menu_item_2.title }
    it { expect(find_locale('Header Menu', primary_locale).text).to include menu_item_2.title }
  end

  context 'menu items color' do
    before do
      knowledge_base.update! color_header_link: color
      visit '/#manage/knowledge_base'
      find('a', text: 'Public Menu').click
    end

    let(:color) { 'rgb(255, 0, 255)' }

    it 'applies color for header preview' do
      elem = first('.kb-menu-preview a')

      expect(elem).to have_computed_style :color, color
    end

    it 'does not apply color for footer preview' do
      elem = all('.kb-menu-preview a')[3]

      expect(elem).not_to have_computed_style :color, color
    end
  end

  context 'edit menu items' do
    before do
      visit '/#manage/knowledge_base'
      find('a', text: 'Public Menu').click
      find_location('Header Menu').find('a', text: 'Edit').click
    end

    it 'edit menu item' do
      in_modal do
        find('input') { |elem| elem.value == menu_item_1.title }.fill_in with: 'test menu'
        find('button', text: 'Submit').click
      end

      expect(find_locale('Header Menu', primary_locale).text).to include 'test menu'
    end

    it 'adds menu item' do
      in_modal do
        container = find(:css, 'h2', text: alternative_locale.system_locale.name).find(:xpath, '..')
        container.find('a', text: 'Add').click

        container.find('input') { |elem| elem['data-name'] == 'title' }.fill_in with: 'new item'
        container.find('input') { |elem| elem['data-name'] == 'url' }.fill_in with: '/new_item'

        find('button', text: 'Submit').click
      end

      expect(find_locale('Header Menu', alternative_locale).text).to include 'new item'
    end

    it 'deletes menu item' do
      in_modal do
        find('input') { |elem| elem.value == menu_item_1.title }
          .ancestor('tr')
          .find('.js-remove')
          .click

        find('button', text: 'Submit').click
      end

      expect(find_locale('Header Menu', alternative_locale).text).not_to include menu_item_1.title
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
