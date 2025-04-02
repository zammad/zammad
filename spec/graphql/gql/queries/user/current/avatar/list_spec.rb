# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::Avatar::List, type: :graphql do
  context 'when fetching avatar' do
    let(:query) do
      <<~QUERY
        query userCurrentAvatarList {
          userCurrentAvatarList {
            id
            default
            deletable
            initial
          }
        }
      QUERY
    end

    context 'when user is authenticated, but has no permission', authenticated_as: :agent do
      let(:agent) { create(:agent, roles: []) }

      before do
        gql.execute(query)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end

    context 'when authorized', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      context 'when no avatar was uploaded' do
        it 'only returns the default avatar' do
          gql.execute(query)
          expect(gql.result.data.first).to include(
            'default' => true,
            'initial' => true,
          )
        end
      end

      context 'when avatar is available' do
        before do
          [
            Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=='),
            Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==')
          ].each do |img|
            avatar = Avatar.add(
              object:        'User',
              o_id:          agent.id,
              full:          {
                content:   img,
                mime_type: 'image/png',
              },
              resize:        {
                content:   img,
                mime_type: 'image/png',
              },
              source:        "upload #{Time.zone.now} #{SecureRandom.hex(256)}",
              deletable:     true,
              created_by_id: agent.id,
              updated_by_id: agent.id,
            )
            agent.update!(image: avatar.store_hash)
          end
        end

        it 'returns data', :aggregate_failures do
          gql.execute(query)
          result = gql.result.data

          expect(result.size).to eq(3) # 2 uploaded avatars + 1 default avatar
          expect(result.first.keys).to contain_exactly('id', 'default', 'deletable', 'initial')
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
