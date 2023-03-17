# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Account::Avatar::Add, type: :graphql do
  context 'when creating a new avatar for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { images: { full: base64_img, resize: base64_img } } }
    let(:base64_img)    { "data:#{mime_type};base64,iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg==" }
    let(:mime_type)     { 'image/png' }
    let(:execute_query) { true }

    let(:query) do
      <<~QUERY
        mutation accountAvatarAdd($images: AvatarInput!) {
          accountAvatarAdd(images: $images) {
            avatar {
              id
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    before do
      next if !execute_query

      gql.execute(query, variables: variables)
    end

    context 'with valid image' do
      it 'returns the newly created avatar' do
        expect(gql.result.data['avatar']).not_to be_nil
      end

      it 'updates the image for the user' do
        avatar = Gql::ZammadSchema.verified_object_from_id(gql.result.data['avatar']['id'], type: Avatar)
        expect(agent.reload.image).to eq(avatar.store_hash)
      end

      context 'when checking the Store' do
        let(:execute_query) { false }

        it 'increases the amount of records correctly' do
          expect { gql.execute(query, variables: variables) }.to change(Store, :count).by(2)
        end
      end
    end

    context 'with invalid image' do
      let(:base64_img) { 'invalid image' }

      it 'fails with error message' do
        expect(gql.result.data['errors'][0]).to include('message' => 'The image is invalid.')
      end
    end

    context 'with invalid mime-type' do
      let(:mime_type) { 'image/tiff' }

      it 'fails with error message' do
        expect(gql.result.data['errors'][0]).to include('message' => 'The MIME type of the image is invalid.')
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
