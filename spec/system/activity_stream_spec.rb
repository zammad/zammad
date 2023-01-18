# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Dashboard', type: :system do
  context 'when Ticket has name attribute', authenticated_as: :authenticate, db_strategy: :reset do
    def authenticate
      create(:object_manager_attribute_text, name: 'name', display: 'Name')
      ObjectManager::Attribute.migration_execute
      true
    end

    let(:ticket)     { Ticket.first }
    let(:name_value) { 'activity stream test' }

    before do
      ticket.update! name: name_value
    end

    it 'shows ticket title in activity stream' do
      visit '/'

      within '.sidebar' do
        expect(page)
          .to have_no_text(name_value)
          .and have_text(ticket.title)
      end
    end
  end
end
