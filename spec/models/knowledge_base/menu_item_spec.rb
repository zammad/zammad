require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::MenuItem, type: :model do
  subject(:kb_menu_item) { create(:knowledge_base_menu_item) }

  include_context 'factory'

  context 'when url without prefix is added' do
    before { kb_menu_item.update(url: Faker::Internet.domain_name) }

    it 'is saved' do
      expect(kb_menu_item).not_to be_changed
    end

    it 'prefix is added to hostname' do
      expect(kb_menu_item.url).to start_with 'http://'
    end
  end

  context 'when url with custom prefix is added' do
    before { kb_menu_item.update(url: "scheme://#{Faker::Internet.domain_name}") }

    it 'is saved' do
      expect(kb_menu_item).not_to be_changed
    end

    it 'given scheme is not touched' do
      expect(kb_menu_item.url).to start_with 'scheme://'
    end
  end

  context 'protocol prefix is not added to relative url' do
    before { kb_menu_item.update(url: '/loremipsum') }

    it 'is saved' do
      expect(kb_menu_item).not_to be_changed
    end

    it 'path is not modified' do
      expect(kb_menu_item.url).not_to start_with 'http://'
    end
  end
end
