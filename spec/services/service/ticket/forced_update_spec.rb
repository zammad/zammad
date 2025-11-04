# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ForcedUpdate, current_user_id: -> { user.id } do
  let(:user)   { create(:agent, groups: [ticket.group]) }
  let(:ticket) { create(:ticket) }

  context 'when updating a ticket with a missing required field', db_strategy: :reset do
    before do
      ticket

      create(:object_manager_attribute_text, :required_screen)
      ObjectManager::Attribute.migration_execute
    end

    it 'still saves the new value' do
      title = Faker::Lorem.word

      described_class.new(ticket, title:).execute

      expect(ticket.reload).to have_attributes(title:)
    end
  end
end
