# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ZammadSchema, type: :graphql do

  it 'generates GraphQL::ID values' do
    expect(described_class.id_from_object(Ticket.first)).to eq('gid://zammad/Ticket/1')
  end

  it 'resolves GraphQL::ID values' do
    expect(described_class.object_from_id('gid://zammad/Ticket/1')).to eq(Ticket.first)
  end

  it 'resolves internal IDs to GraphQL::IDs' do
    expect(described_class.id_from_internal_id(Ticket, 1)).to eq('gid://zammad/Ticket/1')
  end

  it 'resolves internal IDs to GraphQL::IDs (with class name as string)' do
    expect(described_class.id_from_internal_id('Ticket', 1)).to eq('gid://zammad/Ticket/1')
  end
end
