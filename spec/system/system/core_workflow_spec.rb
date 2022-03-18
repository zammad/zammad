# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System > Core Workflows', type: :system do
  before do
    ensure_websocket do
      visit 'system/core_workflow'
    end
  end

  it 'shows correct screens and objects' do
    click_link 'New Workflow'
    expect(all("select[name='object'] option").map(&:text)).not_to include('Sla')
    find_field('object').select 'Ticket'
    expect(all("select[name='preferences::screen'] option").map(&:text)).to eq(['Creation mask', 'Edit mask'])
  end

  describe 'for saved entry', authenticated_as: :authenticate do
    def authenticate
      create(:core_workflow,
             name:        'special workflow',
             object:      'Ticket',
             changeable:  true,
             preferences: {
               screen: ['edit'],
             })
      true
    end

    it 'shows correct screens and objects' do
      first('tr.item').first('td').click
      expect(all("select[name='object'] option").map(&:text)).not_to include('Sla')
      expect(all("select[name='preferences::screen'] option").map(&:text)).to eq(['Creation mask', 'Edit mask'])
      find_field('object').select '-'
      expect(all("select[name='preferences::screen'] option").map(&:text)).to eq(['-'])
    end
  end
end
