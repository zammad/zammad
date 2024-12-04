# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::ZammadSchema, type: :graphql do

  describe '.id_from_object' do
    it 'generates GraphQL::ID values' do
      expect(described_class.id_from_object(Ticket.first)).to eq('gid://zammad/Ticket/1')
    end
  end

  describe '.object_from_id' do
    it 'resolves GraphQL::ID values' do
      expect(described_class.object_from_id('gid://zammad/Ticket/1')).to eq(Ticket.first)
    end
  end

  describe '.id_from_internal_id' do
    it 'resolves internal IDs to GraphQL::IDs' do
      expect(described_class.id_from_internal_id(Ticket, 1)).to eq('gid://zammad/Ticket/1')
    end

    it 'resolves internal IDs to GraphQL::IDs (with class name as string)' do
      expect(described_class.id_from_internal_id('Ticket', 1)).to eq('gid://zammad/Ticket/1')
    end
  end

  describe '.internal_id_from_id' do
    let(:id)         { [*(1..999)].sample }
    let(:gid_string) { "gid://zammad/Ticket/#{id}" }

    it 'returns internal ID based on given global ID' do
      expect(described_class.internal_id_from_id(gid_string)).to eq(id)
    end

    it 'returns nil if class is not allowed' do
      expect(described_class.internal_id_from_id(gid_string, type: User)).to be_nil
    end

    it 'returns internal ID if class is allowed' do
      expect(described_class.internal_id_from_id(gid_string, type: Ticket)).to eq(id)
    end
  end

  describe '.internal_ids_from_ids' do
    let(:id)         { [*(1..999)].sample }
    let(:gid_string) { "gid://zammad/Ticket/#{id}" }

    it 'returns internal IDs based on given global IDs' do
      expect(described_class.internal_ids_from_ids([gid_string])).to eq([id])
    end

    it 'returns internal IDs if class is allowed' do
      expect(described_class.internal_ids_from_ids([gid_string], type: Ticket)).to eq([id])
    end

    it 'skips item if class is not allowed' do
      expect(described_class.internal_ids_from_ids([gid_string], type: User)).to be_blank
    end
  end

  describe '.local_uris_from_ids' do
    let(:id)         { [*(1..999)].sample }
    let(:gid_string) { "gid://zammad/Ticket/#{id}" }
    let(:gid)        { GlobalID.new(gid_string) }

    it 'returns given global ID as GlobalID' do
      expect(described_class.local_uris_from_ids([gid_string])).to eq([gid])
    end

    it 'returns given global ID if class is allowed' do
      expect(described_class.local_uris_from_ids([gid_string], type: Ticket)).to eq([gid])
    end

    it 'skips item if class is not allowed' do
      expect(described_class.local_uris_from_ids([gid_string], type: User)).to be_blank
    end
  end
end
