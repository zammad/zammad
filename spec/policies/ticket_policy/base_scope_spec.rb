# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketPolicy::BaseScope do
  subject(:scope) { described_class.new(user) }

  describe '#resolve' do
    context 'when querying for agent user' do
      let(:user) { create(:agent) }

      it 'raises NoMethodError (undefined on abstract base class)' do
        expect { scope.resolve }.to raise_error(NoMethodError)
      end
    end

    context 'when querying for customer user' do
      let(:user) { create(:customer) }

      it 'raises NoMethodError (undefined on abstract base class)' do
        expect { scope.resolve }.to raise_error(NoMethodError)
      end
    end
  end
end
