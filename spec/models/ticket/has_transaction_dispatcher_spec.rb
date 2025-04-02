# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'HasTransactionDispatcher', db_strategy: :reset, type: :model do
  let(:ticket) { create(:ticket) }
  let(:agent)  { create(:agent, groups: [ticket.group]) }

  describe '#after_update' do
    context 'when ticket is updated without sending required values' do
      before do
        UserInfo.current_user_id = agent.id

        create(:object_manager_attribute_text, :required_screen)
        ObjectManager::Attribute.migration_execute
      end

      it 'does not call the TransactionDispatcher after_update hook', :aggregate_failures do
        allow(TransactionDispatcher).to receive(:after_update)

        expect { ticket.update(title: 'New title', screen: 'edit') }.to raise_error(Exceptions::ApplicationModel)
        expect(TransactionDispatcher).not_to have_received(:after_update)
      end
    end
  end
end
