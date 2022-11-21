# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ZammadSchema, type: :graphql do

  it 'generates GraphQL::ID values' do
    expect(described_class.id_from_object(Ticket.first)).to eq('gid://zammad/Ticket/1')
  end

  it 'resolves GraphQL::ID values' do
    expect(described_class.object_from_id('gid://zammad/Ticket/1')).to eq(Ticket.first)
  end
end
