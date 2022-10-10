# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Templates', type: :system do
  context 'with ajax pagination' do
    include_examples 'pagination', model: :template, klass: Template, path: 'manage/templates'
  end

  context 'when creating a new template' do
    before do
      visit '#manage/templates'

      within(:active_content) do
        find('[data-type=new]').click
      end
    end

    it 'with default attributes' do
      in_modal do
        fill_in('name', with: 'template 1')
        click_button('Submit')
      end
    end
  end

end
