# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Groups', type: :system do
  context 'ajax pagination' do
    include_examples 'pagination', model: :group, klass: Group, path: 'manage/groups'
  end

  context "Issue 2544 - Can't remove auto assignment timeout" do
    before do
      visit '/#manage/groups'
    end

    it 'is possible to reset the assignment timeout of a group' do
      find('td', text: 'Users').click
      fill_in 'Assignment Timeout', with: '30'
      find('button', text: 'Submit').click
      expect(Group.find_by(name: 'Users').assignment_timeout).to eq(30)

      find('td', text: 'Users').click
      fill_in 'Assignment Timeout', with: ''
      find('button', text: 'Submit').click
      expect(Group.find_by(name: 'Users').assignment_timeout).to be nil
    end
  end
end
