# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > External Data Source Attribute', db_adapter: :postgresql, db_strategy: :reset, searchindex: true, type: :system do
  let(:search_url) { "#{Setting.get('es_url')}/#{Setting.get('es_index')}_test_user/_search?q=\#{search.term}" }
  let(:external_data_source_attribute) do
    create(:object_manager_attribute_autocompletion_ajax_external_data_source, :shown_screen, :elastic_search, search_url: search_url, name: 'external_data_source_attribute')
  end
  let(:group)          { Group.find_by(name: 'Users') }
  let(:ticket)         { create(:ticket, group: group, customer: customer1) }
  let(:customer1)      { create(:customer, firstname: SecureRandom.uuid) }
  let(:customer2)      { create(:customer, firstname: searchterm) }
  let(:searchterm)     { SecureRandom.uuid }

  before do
    customer1
    customer2
    searchindex_model_reload([User])

    external_data_source_attribute
    ObjectManager::Attribute.migration_execute

    visit "ticket/zoom/#{ticket.id}"
  end

  context 'when external data source attribute is used' do
    it 'search and select value' do
      set_external_data_source_value('external_data_source_attribute', searchterm, customer2.email)

      click('.js-attributeBar .js-submit')
      expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')

      expect(ticket.reload.external_data_source_attribute).to eq({ 'value' => customer2.id.to_s, 'label' => customer2.email })
    end

    context 'when search template variables are used' do
      let(:search_url) { "#{Setting.get('es_url')}/#{Setting.get('es_index')}_test_user/_search?q=\"\#{ticket.customer.email}\"" }

      it 'search only with wildcard' do
        set_external_data_source_value('external_data_source_attribute', '*', customer1.firstname)

        click('.js-attributeBar .js-submit')
        expect(page).to have_no_css('.js-submitDropdown .js-submit[disabled]')

        expect(ticket.reload.external_data_source_attribute).to eq({ 'value' => customer1.id.to_s, 'label' => customer1.email })
      end
    end
  end
end
