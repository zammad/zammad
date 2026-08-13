# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::BaseUnion do
  describe '.extensions' do
    context 'when the union has no extensions directory' do
      it 'returns an empty array' do
        expect(Gql::Types::BaseUnionSpec::WithoutExtensionsType.extensions).to eq([])
      end
    end

    context 'when the union has an extensions directory' do
      it 'discovers the extension classes, sorted by name' do
        expect(Gql::Types::BaseUnionSpec::WithExtensionsType.extensions).to eq(
          [
            Gql::Types::BaseUnionSpec::WithExtensionsType::Extensions::AlphaExtension,
            Gql::Types::BaseUnionSpec::WithExtensionsType::Extensions::BetaExtension,
          ]
        )
      end
    end
  end

  describe '.extension_types' do
    context 'when the union has no extensions directory' do
      it 'returns an empty array' do
        expect(Gql::Types::BaseUnionSpec::WithoutExtensionsType.extension_types).to eq([])
      end
    end

    context 'when the union has an extensions directory' do
      it 'flat-maps the possible_types of all extensions' do
        expect(Gql::Types::BaseUnionSpec::WithExtensionsType.extension_types).to eq(
          [Gql::Types::UserType, Gql::Types::OrganizationType]
        )
      end
    end
  end

  # Same append pattern used by e.g. user/taskbar_item_entity_type.rb ('possible_types ..., *extension_types').
  context 'when a union appends *extension_types to its own possible_types' do
    it 'includes the extension-provided types, in order' do
      expect(Gql::Types::BaseUnionSpec::WithExtensionsType.possible_types).to eq(
        [Gql::Types::TicketType, Gql::Types::UserType, Gql::Types::OrganizationType]
      )
    end
  end

  # Special case (see SearchResult::ItemType): extensions provide '.models' instead of
  #   '.possible_types', and 'possible_types' is derived from them at class-body time.
  context 'when a union derives possible_types from a .models extension pattern' do
    it 'includes extension-provided models in searchable_models, in order' do
      expect(Gql::Types::BaseUnionSpec::WithModelExtensionsType.searchable_models).to eq([Ticket, Organization])
    end

    it 'freezes the memoized searchable_models array' do
      expect(Gql::Types::BaseUnionSpec::WithModelExtensionsType.searchable_models).to be_frozen
    end

    it 'includes extension-provided models in the load-time possible_types, in order' do
      expect(Gql::Types::BaseUnionSpec::WithModelExtensionsType.possible_types).to eq(
        [Gql::Types::TicketType, Gql::Types::OrganizationType]
      )
    end
  end
end
