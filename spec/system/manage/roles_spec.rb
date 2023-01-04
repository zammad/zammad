# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Role', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :role, klass: Role, path: 'manage/roles'
  end

  # https://github.com/zammad/zammad/issues/4100
  context 'creating a new role' do
    before do
      visit '#manage/roles'

      within(:active_content) do
        find('[data-type=new]').click
      end
    end

    it 'handles permission checkboxes correctly' do
      in_modal do
        scroll_into_view 'table.settings-list'
        within 'table.settings-list tbody tr:first-child' do
          click 'input[value="full"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).to be_checked

          click 'input[value="read"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).not_to be_checked
          expect(find('input[value="read"]', visible: :all)).to be_checked

          click 'input[value="full"]', visible: :all
          expect(find('input[value="full"]', visible: :all)).to be_checked
          expect(find('input[value="read"]', visible: :all)).not_to be_checked
        end
      end
    end
  end
end
