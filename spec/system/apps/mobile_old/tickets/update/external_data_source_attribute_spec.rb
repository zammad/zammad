# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > External Data Source Attribute', app: :mobile, db_adapter: :postgresql, db_strategy: :reset, searchindex: true, type: :system do
  let(:search_url) { "#{Setting.get('es_url')}/#{Setting.get('es_index')}_test_user/_search?q=\#{search.term}" }
  let(:external_data_source_attribute) do
    create(:object_manager_attribute_autocompletion_ajax_external_data_source, :shown_screen, :elastic_search, search_url: search_url, name: 'external_data_source_attribute', display: 'External data source')
  end
  let(:group)          { Group.find_by(name: 'Users') }
  let(:ticket)         { create(:ticket, group: group, customer: customer1) }
  let(:customer1)      { create(:customer, firstname: SecureRandom.uuid) }
  let(:customer2)      { create(:customer, firstname: searchterm) }
  let(:searchterm)     { SecureRandom.uuid }

  def submit_form
    find_button('Save').click
    wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
  end

  before do
    customer1
    customer2
    searchindex_model_reload([User])

    external_data_source_attribute
    ObjectManager::Attribute.migration_execute

    visit "/tickets/#{ticket.id}/information"
  end

  context 'when external data source attribute is used' do
    it 'search and select value' do
      find_autocomplete('External data source').search_for_option(searchterm).select_option(customer2.email)

      submit_form

      expect(ticket.reload.external_data_source_attribute).to eq({ 'value' => customer2.id.to_s, 'label' => customer2.email })
    end

    context 'when search template variables are used' do
      let(:search_url) { "#{Setting.get('es_url')}/#{Setting.get('es_index')}_test_user/_search?q=\"\#{ticket.customer.email}\"" }

      it 'search only with wildcard' do
        find_autocomplete('External data source').search_for_option(customer1.firstname).select_option(customer1.email)

        submit_form

        expect(ticket.reload.external_data_source_attribute).to eq({ 'value' => customer1.id.to_s, 'label' => customer1.email })
      end
    end
  end
end
