# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::MenuItem, type: :model do
  subject(:kb_menu_item) { create(:knowledge_base_menu_item) }

  include_context 'factory'

  context 'item' do
    it { is_expected.to validate_presence_of  :title }
    it { is_expected.to validate_presence_of  :url }
    it { is_expected.to validate_presence_of  :location }
    it { is_expected.to validate_inclusion_of(:location).in_array(%w[header footer]) }
  end

  context 'has scopes for' do
    let(:kb_locale) { kb_menu_item.kb_locale }
    let(:scope)     { described_class.where(kb_locale: kb_locale) }

    let!(:header) { create(:knowledge_base_menu_item, :for_header, kb_locale: kb_locale) }
    let!(:footer) { create(:knowledge_base_menu_item, :for_footer, kb_locale: kb_locale) }

    it 'header' do
      expect(scope.location_header).to match [kb_menu_item, header]
    end

    it 'footer' do
      expect(scope.location_footer).to match [footer]
    end
  end

  context 'when url' do
    context 'without prefix is added' do
      before { kb_menu_item.update(url: Faker::Internet.domain_name) }

      it 'is saved' do
        expect(kb_menu_item).not_to be_changed
      end

      it 'prefix is added to hostname' do
        expect(kb_menu_item.url).to start_with 'http://'
      end
    end

    context 'with custom prefix is added' do
      before { kb_menu_item.update(url: "scheme://#{Faker::Internet.domain_name}") }

      it 'is saved' do
        expect(kb_menu_item).not_to be_changed
      end

      it 'given scheme is not touched' do
        expect(kb_menu_item.url).to start_with 'scheme://'
      end
    end

    context 'is relative and protocol prefix is not added' do
      before { kb_menu_item.update(url: '/loremipsum') }

      it 'is saved' do
        expect(kb_menu_item).not_to be_changed
      end

      it 'path is not modified' do
        expect(kb_menu_item.url).not_to start_with 'http://'
      end
    end
  end
end
