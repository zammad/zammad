# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Account::Avatar::Active, type: :graphql do
  context 'when fetching avatar' do
    let(:query) do
      <<~QUERY
        query accountAvatarActive {
          accountAvatarActive {
            id
          }
        }
      QUERY
    end

    context 'when authorized', authenticated_as: :agent do
      let(:agent)   { create(:agent) }
      let!(:avatar) { nil }

      before do
        gql.execute(query)
      end

      context 'when no avatar is available' do
        it 'returns nil' do
          expect(gql.result.data).to be_nil
        end
      end

      context 'when avatar is available' do
        let(:base64_img) { Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==') }
        let!(:avatar) do
          avatar = Avatar.add(
            object:        'User',
            o_id:          agent.id,
            full:          {
              content:   base64_img,
              mime_type: 'image/png',
            },
            resize:        {
              content:   base64_img,
              mime_type: 'image/png',
            },
            source:        "upload #{Time.zone.now}",
            deletable:     true,
            created_by_id: agent.id,
            updated_by_id: agent.id,
          )
          agent.update!(image: avatar.store_hash)
          avatar
        end

        it 'returns data' do
          expect(gql.result.data['id']).to eq(gql.id(avatar))
        end
      end
    end

    context 'when unauthenticated' do
      before do
        gql.execute(query)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
