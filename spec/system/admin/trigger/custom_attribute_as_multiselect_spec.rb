require 'rails_helper'

RSpec.describe 'Admin Panel > Trigger', type: :system do
  it 'custom select attribute allows to select multiple values', db_strategy: :reset do
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
