# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
RSpec.describe ObjectManager, aggregate_failures: true, type: :model do

  describe 'class methods' do
    describe 'list_objects' do
      it 'returns an array of objects' do
        expect(described_class.list_objects).to be_an(Array)
        expect(described_class.list_objects.sort).to match_array(%w[Group Organization User Ticket TicketArticle])
      end
    end

    describe 'list_frontend_objects' do
      it 'returns an array of objects' do
        expect(described_class.list_frontend_objects).to be_an(Array)
        expect(described_class.list_frontend_objects.sort).to match_array(%w[Group Organization User Ticket])
      end
    end
  end
end
