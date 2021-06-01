# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Trigger', type: :system do

  context 'Selector' do

    context 'custom attribute', db_strategy: :reset do

      it 'enables selection of multiple values for select attribute' do
        attribute = create_attribute :object_manager_attribute_select,
                                     data_option: {
                                       options:    {
                                         'name 1': 'name 1',
                                         'name 2': 'name 2',
                                       },
                                       default:    '',
                                       null:       false,
                                       relation:   '',
                                       maxlength:  255,
                                       nulloption: true,
                                     }

        visit '/#manage/trigger'
        click '.page-header-meta .btn--success'

        modal_ready

        within '.modal .ticket_selector' do
          find('.js-attributeSelector select').select(attribute.display)

          expect(find('.js-value select')).to be_multiple
        end
      end
    end

    it 'sets a customer email address with no @ character' do
      visit '/#manage/trigger'

      click '.page-header-meta .btn--success'
      modal_ready

      find(".js-attributeSelector select option[value='customer.email']").select_option
      fill_in 'condition::customer.email::value', with: 'zammad.com'
      fill_in 'Name', with: 'trigger 1'
      click '.js-submit'
      modal_disappear
    end
  end

  context 'Perform' do

    context 'Tags' do

      it 'shows tag selection list in foreground' do
        tag_item = create :tag_item

        visit '/#manage/trigger'
        click_on 'New Trigger'

        modal_ready

        within '.modal .ticket_perform_action' do
          find('.js-attributeSelector select').select('Tags')

          input = find('.js-value .token-input')
          input.fill_in with: tag_item.name.slice(0, 3)
        end

        expect(page).to have_css('.ui-autocomplete.ui-widget-content') { |elem| !elem.obscured? }
      end
    end
  end

  context 'ajax pagination' do
    include_examples 'pagination', model: :trigger, klass: Trigger, path: 'manage/trigger'
  end
end
