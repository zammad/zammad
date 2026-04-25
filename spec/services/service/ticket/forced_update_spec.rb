# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::ForcedUpdate, current_user_id: -> { user.id } do
  subject(:service_result) { described_class.with_current_user(user).execute(ticket, title:) }

  let(:user)   { create(:agent, groups: [ticket.group]) }
  let(:ticket) { create(:ticket) }
  let(:title)  { Faker::Lorem.word }

  context 'when updating a ticket with a missing required field', db_strategy: :reset do
    before do
      ticket

      create(:object_manager_attribute_text, :required_screen)
      ObjectManager::Attribute.migration_execute
    end

    it 'still saves the new value' do
      service_result

      expect(ticket.reload).to have_attributes(title:)
    end
  end
end
