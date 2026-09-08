# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::SearchResult::ItemType do
  # Guards against regressions from the union extension mechanism (see base_union_spec.rb):
  # without addon extensions, the core schema must stay exactly as before.
  it 'exposes exactly the built-in searchable types' do
    expect(described_class.possible_types).to eq([
                                                   Gql::Types::TicketType,
                                                   Gql::Types::UserType,
                                                   Gql::Types::OrganizationType,
                                                   Gql::Types::KnowledgeBase::Answer::TranslationType,
                                                 ])
  end

  it 'exposes exactly the built-in searchable models' do
    expect(described_class.searchable_models).to eq([Ticket, User, Organization, KnowledgeBase::Answer::Translation])
  end

  # The namespace separator cannot survive into a GraphQL enum value, so it is encoded rather than
  #   dropped (IdentifierName). The frontend's search plugin is keyed on the generated member, so
  #   the encoding is part of the contract rather than an implementation detail.
  it 'encodes the namespaced model into the searchable models enum' do
    expect(Gql::Types::Enum::SearchableModelsType.values.keys).to include('KnowledgeBase__Answer__Translation')
  end
end
