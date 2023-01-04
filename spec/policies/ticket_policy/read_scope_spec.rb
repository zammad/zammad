# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'policies/ticket_policy/shared_examples'

RSpec.describe TicketPolicy::ReadScope do
  context 'with default scope' do
    subject(:scope) { described_class.new(user) }

    describe '#resolve' do
      context 'when querying for agent user' do
        include_examples 'for agent user', 'read'
      end

      context 'when querying for customer user' do
        include_examples 'for customer user'
      end
    end
  end

  context 'with predefined, impossible scope' do
    subject(:scope) { described_class.new(user, Ticket.where(id: -1)) }

    describe '#resolve' do
      include_examples 'for agent user with predefined but impossible context'
    end
  end
end
