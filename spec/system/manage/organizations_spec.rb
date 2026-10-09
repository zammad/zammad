# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Organizations', type: :system do

  context 'custom attribute' do

    context 'text' do

      context 'linktemplate' do

        it 'creates record', db_strategy: :reset do

          # required to edit attribute in admin interface
          screens = { create: { 'admin.organization': { shown: true, required: false } } }

          attribute = create(:object_manager_attribute_text,
                             object_name:             'Organization',
                             screens:                 screens,
                             additional_data_options: { linktemplate: 'https://example.com' })

          ObjectManager::Attribute.migration_execute

          refresh

          visit 'manage/organizations'

          within(:active_content) do
            click '[data-type="new"]'
          end

          name = "Organization #{SecureRandom.uuid}"

          in_modal do
            fill_in 'name', with: name
            fill_in attribute.name, with: 'value'

            click '.js-submit'
          end

          within(:active_content) do
            expect(page).to have_text name
          end
        end
      end
    end

    context 'with tree select defaults', db_strategy: :reset do
      let(:screens)               { { create: { '-all-' => { shown: true } } } }
      let!(:tree_attribute)       { create(:object_manager_attribute_tree_select, object_name: 'Organization', screens: screens, default: 'Incident::Hardware::Mouse') }
      let!(:multi_tree_attribute) { create(:object_manager_attribute_multi_tree_select, object_name: 'Organization', screens: screens, default: ['Incident', 'Incident::Hardware::Mouse']) }

      before do
        ObjectManager::Attribute.migration_execute
        refresh

        visit 'manage/organizations'

        within(:active_content) do
          click '[data-type="new"]'
        end
      end

      it 'prefills the default values' do
        in_modal do
          check_tree_select_field_value(tree_attribute.name, 'Incident::Hardware::Mouse')

          expect(page).to have_css("div[data-attribute-name='#{multi_tree_attribute.name}'] span.token-label", exact_text: 'Incident')
          expect(page).to have_css("div[data-attribute-name='#{multi_tree_attribute.name}'] span.token-label", exact_text: 'Incident › Hardware › Mouse')
          expect(find("select[name='#{multi_tree_attribute.name}']", visible: :all).value).to contain_exactly('Incident', 'Incident::Hardware::Mouse')
        end
      end
    end
  end

  context 'when ajax pagination' do
    include_examples 'pagination', model: :organization, klass: Organization, path: 'manage/organizations'
  end
end
