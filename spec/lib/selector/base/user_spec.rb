# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Selector::Base, 'user', searchindex: true do
  describe 'Basic tests' do
    let(:user_1)   { create(:user, firstname: 'Philipp J.', lastname: 'Fry') }
    let(:user_2)   { create(:user, firstname: 'Turanga', lastname: 'Leela') }
    let(:user_3)   { create(:user, firstname: 'Bender', lastname: 'Rodriguez') }

    before do
      user_1 && user_2 && user_3
      searchindex_model_reload([User])
    end

    it 'does find users by firstname', :aggregate_failures do
      condition = {
        operator:   'OR',
        conditions: [
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_1.firstname,
          },
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_2.firstname,
          },
          {
            name:     'user.firstname',
            operator: 'contains',
            value:    user_3.firstname,
          },
        ]
      }

      count, = User.selectors(condition)
      expect(count).to eq(3)

      result = SearchIndexBackend.selectors('User', condition)
      expect(result[:count]).to eq(3)
    end
  end
end
