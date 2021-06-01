# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

require 'system/examples/text_modules_examples'

RSpec.describe 'User Profile', type: :system do
  let(:customer) { create(:customer) }

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      customer
      create :object_manager_attribute_text, object_name: 'User', name: 'maxtest', display: 'maxtest', screens: attributes_for(:required_screen), data_option: {
        'type'      => 'text',
        'maxlength' => 3,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket create' do
      visit "#user/profile/#{customer.id}"
      within(:active_content) do
        page.find('.profile .js-action').click
        page.find('.profile li[data-type=edit]').click
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end
end
